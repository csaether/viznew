# == Schema Information
# Schema version: 20111123043408
#
# Table name: runs
#
#  id             :integer         not null, primary key
#  on_obs_chg_id  :integer
#  off_obs_chg_id :integer
#  start_time     :datetime
#  duration       :integer
#  load_desc_id   :integer
#  arr_ag         :binary
#

class Run < ActiveRecord::Base
  composed_of :arr_ag

  belongs_to :load_desc
  belongs_to :on_chg, :class_name => "ObsChg",
             :foreign_key => :on_obs_chg_id
  belongs_to :off_chg, :class_name => "ObsChg",
             :foreign_key => :off_obs_chg_id

  def self.per_page
    20
  end

  def before_destroy
    unless off_obs_chg_id.nil?
      oc = ObsChg.find off_obs_chg_id
      if oc.run_offs.count == 1
        oc.chg_sig = nil
        oc.training = false
        oc.save!
      end
    end
    unless on_obs_chg_id.nil?
      oc = ObsChg.find on_obs_chg_id
      if oc.run_ons.count == 1
        oc.chg_sig = nil
        oc.training = false
        oc.save!
      end
    end
  end

  def Run.addcloseons( maxdist = 2 )

    Run.connection.execute('PRAGMA synchronous=0;')
    sid = 0
    while true do
      oba = ObsChg.find :all, :limit => 100,
        :conditions => ['wattdiff > 0 and id > ?', sid]

      break if oba.blank?
      sid = oba[-1].id
      puts "at " + sid.to_s
      oba.each do |oc|
        next unless oc.run_ons.empty?  # if any, will pass over
        # here if obs_chg does not have a run
        cs = ChgSig.close oc, maxdist
        next if cs.nil?  # did not find match
        # here if we got a sig match
        oc.update_attribute :chg_sig, cs
        cs.load_descs.each do |ld|
          Run.create! :on_chg => oc, :load_desc => ld,
                :start_time => oc.pwr_datum.dtime
          puts cs.name + " close to " + oc.wattdiff.to_s
        end
      end
    end
    nil
  rescue Exception => e  # really $!
    puts e
debugger
  end

  def Run.allscan( ondistlimit = 5, offdistlimit = 5 )
=begin
Scan all obschgs, creating new runs from on events, as well as
accumlating the best off events for currently open runs
=end

    Run.connection.execute('PRAGMA synchronous=0;')
    openruns={}  # of open runs keyed by load desc
    sid = 0
    while true do
      oba = ObsChg.find :all, :limit => 100,
        :conditions => ['id > ?', sid]

      break if oba.blank?
      puts "at " + sid.to_s
      sid = oba[-1].id
      oba.each do |oc|

        # do different things whether on or off event
        if oc.wattdiff > 0

          unless oc.run_ons.empty?
            # this oc has a run. update openruns appropriately.
            oc.run_ons.each do |r|
              if r.off_chg.nil?
                # this could be the place to close a previous run, if one
                openruns[r.load_desc] = r
              else
                openruns.delete r.load_desc
              end
            end
            next  # nothing else to do with this one
          end

          # here if obs_chg does not have a run

          cs = ChgSig.close oc, ondistlimit
          next if cs.nil?  # did not find close enough match
          next if cs.load_descs.empty?  # no load with this yet
          # here if we got a sig match
          oc.update_attribute :chg_sig, cs
          cs.load_descs.each do |ld|  # create run for each sig load
            r = Run.create! :on_chg => oc, :load_desc => ld,
            :start_time => oc.pwr_datum.dtime
            openruns[ld] = r
            puts cs.name + " close to " + oc.wattdiff.to_s
          end
        else
          # see how close this off obschg is to closing each open run
          openruns.each do |ld, r|
            offsda = r.arr_ag.arr  # end run candidates
            ld.chg_sigs.each do |cs|
              dist = cs.distance oc
              next if dist > offdistlimit
              dist += ld.dutydist oc.pwr_datum.dtime - r.start_time
              next if dist > offdistlimit
              if offsda.last.nil? || dist < offsda.last[0]
                offsda.push [dist, oc.id, cs.id]
                offsda.sort!
                offsda.pop if offsda.count > 3
                r.update_attribute :arr_ag, ArrAg.new( offsda )
              end
            end  # chgsigs for a load desc
          end  # each open run
        end  # an off event
      end # each obschg in this batch
    end # while true loop over batches
    nil
  rescue Exception => e  # really $!
    puts e
debugger
  end

  def closerun( maxdist = 2.0 )

    offcand = arr_ag.arr.first
    return if offcand.nil?  # got nothing to try
    return if offcand[0] > maxdist  # not even close
    offc = ObsChg.find offcand[1]
    return unless offc.run_offs.empty?  # someone else got it first
    return unless offc.chg_sig.nil?  # if this okay?

    if off_chg.nil?  # nil, then this run has no off change now
      cs = ChgSig.find offcand[2]  # get chg sig
      offc.update_attribute :chg_sig, cs
      self.off_chg = offc
      self.duration = offc.pwr_datum.dtime - start_time
      self.save!
    else  # we already have an off change
=begin
this is bogus - need to revisit
      edist = off_chg.chg_sig.distance off_chg  # existing distance
      if offcand[0] < edist  # would we be closer?
        ccs = ChgSig.find offcand[1]  # candidate chgsig
        if off_chg.chg_sg != ccs  # if distance diff, cs must be ?
          off_chg.update_attribute :chg_sig, ccs
        else
          throw 'wtf'  # how can this be?
        end
        self.update_attribute :off_chg, offc
      end
=end
    end
  end

  def Run.endruns( loadid, redoffchg = false, maxdist = 3.0 )

    unless loadid.nil?
      ra = Run.find_all_by_load_desc_id loadid
    else
      ra = Run.find :all
    end
    ra.each do |r|
      next unless redoffchg || r.off_chg.nil?
      r.closerun( maxdist )
    end
  end

  def bestoffs( maxcans = 5 )
=begin
  Scan for a specific run, accumulating the closest matches
  to end the run, regardless of whether this run already
  has an off, or the observed changes are already associated with
  another run.  The caller can decide what to do with the information.

  returns array of [ distance, obschg.id, chgsig.id ]
=end
    return if on_chg.nil?  # throw instead?  should not happen
    onid = on_chg

    loadruns = self.load_desc.runs.sort{|a,b| a.start_time <=> b.start_time }
    @nxtrun = loadruns.detect{|r| r.start_time > self.start_time }
    if @nxtrun
      hipd = @nxtrun.on_chg.pwr_datum
    end

    offsda = []
    csa = load_desc.chg_sigs  # all possible chg sigs for this run's load

    stop = false
    while !stop do
      oba = ObsChg.find :all, :limit => 100,
        :conditions => ['wattdiff < 0 and id > ?', onid]

      break if oba.blank?

      puts "at " + oba[0].id.to_s
      onid = oba[-1].id
      oba.each do |oc|
        stop = true
        break unless hipd.nil? || oba.pwr_datum_id < hipd.id

        dursecs = oc.pwr_datum.dtime - self.start_time
        break unless load_desc.long_duty.nil? ||
          dursecs <= load_desc.long_duty
        stop = false
        next unless load_desc.short_duty.nil? ||
          dursecs > load_desc.short_duty

        csa.each do |cs|
          d = cs.distance oc
          if offsda.last.nil? || d < offsda.last[0]
            offsda.push [d, oc.id, cs.id]
            offsda.sort!
            offsda.pop if offsda.count > maxcans
          end
        end
      end  # of oba.each
    end
    self.update_attribute :arr_ag, ArrAg.new( offsda )
  rescue Exception => e  # really $!
    puts e
debugger
  end

end
