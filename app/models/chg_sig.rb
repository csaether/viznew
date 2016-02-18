# == Schema Information
# Schema version: 20111123043408
#
# Table name: chg_sigs
#
#  id           :integer         not null, primary key
#  created_at   :datetime
#  updated_at   :datetime
#  wattchg      :integer
#  wattchg_sdev :integer
#  ramp         :float
#  ramp_sdev    :float
#  trans        :integer
#  trans_sdev   :float
#  varchg       :integer
#  varchg_sdev  :integer
#

class ChgSig < ActiveRecord::Base
  has_and_belongs_to_many :load_descs
  has_many :obs_chgs

  def validate
    if wattchg.nil?
      errors.add(:wattchg, "must have a value")
    end
  end

  def after_validation

    if wattchg_sdev.nil?
      s = (wattchg*0.07).to_i
      self.wattchg_sdev = s != 0 ? s : 1
    end
    if ramp.nil?
      self.ramp = 0.0
    end
    if ramp_sdev.nil?
      s = (ramp*0.07).to_i
      self.ramp_sdev = s != 0 ? s : 1
    elsif self.ramp_sdev == 0
      self.ramp_sdev = 0.1
    end
    if trans.nil?
      self.trans = 1
    end
    if trans_sdev.nil?
      self.trans_sdev = 1.0
    end
    if varchg.nil?
      self.varchg = 0
    end
    if varchg_sdev.nil? || varchg_sdev == 0
      self.varchg_sdev = 1
    end
  end

  @@alist = []  #  only has lifetime of a single request, right?

  def after_save
    @@alist = []
  end

  def after_update
    @@alist = []
  end

  def after_destroy
    @@alist = []
  end

  def ChgSig.getalist
    if @@alist.empty?
      @@alist = ChgSig.all
    end
    @@alist
  end

  def resetRuns
    obs_chgs.each do |oc|
      oc.zapRuns unless oc.training
    end
  end

  def name
    if load_descs.empty?
      if wattchg > 0
        return "w#{wattchg}:v#{varchg}:r#{ramp.to_i}"
      else
        return "w#{wattchg}:v#{varchg}"
      end
    end
    n=load_descs[0].name
    1.upto( load_descs.count - 1){|i| n+='+'+load_descs[i].name}
    return n
  end

  def wattdiff( oc )
    oc.wattdiff - wattchg
  end

  def vardiff( oc )
    oc.vardiff - varchg
  end

  def wattdistsq( oc )
    d=wattdiff(oc).abs/(wattchg_sdev.to_f)
    d*d
  end

  def vardistsq( oc )
    d=vardiff(oc).abs/(varchg_sdev.to_f)
    d*d
  end

  def wattdistrat( oc )
    wattdiff(oc).abs/(wattchg_sdev.to_f)
  end

  def rampdistsq( oc )
    return 0 if oc.wattdiff < 0
    return 0 if self.ramp < 5
    rd = (oc.ramp  - self.ramp).abs/ramp_sdev
    return rd*rd
  end

  def distance( oc )

    (Math.sqrt( wattdistsq(oc) + rampdistsq(oc) + vardistsq(oc) )*100).to_i/100.0
#    Math.sqrt(wattdistsq(oc) + rampdistsq(oc))
  rescue Exception => e  # really $!
    9999.9
  end

  def tupdistance( tup ) # wattchg, varchg, ramp

    wd = (tup[0] - wattchg)/(wattchg_sdev.to_f)
    vd = (tup[1] - varchg)/(varchg_sdev.to_f)
    if tup[0] < 0
      rd = 0
    else
      rd = (tup[2] - ramp)/ramp_sdev
    end
    (Math.sqrt( wd*wd + vd*vd + rd*rd )*100).to_i/100.0
  rescue Exception => e  # really $!
    9999.9
  end

  def ChgSig.closetup( tup )

    cslist = getalist
    bdis = 9999999.9
    bi = nil

    cslist.count.times do |i|
      dis = cslist[i].tupdistance( tup )
      if dis < bdis
        bdis = dis
        bi = i
      end
    end
    raise "nobody close?" if bi.nil?
    return bdis, cslist[bi]
  end

  def ChgSig.distances( oc, max = 10 )
    cslist = getalist
    disarr = Array.new
    cslist.count.times do |i|
      dist = cslist[i].distance oc
      disarr.push [ dist, cslist[i] ] if dist < max
    end
    return disarr
  end

  def ChgSig.choices( oc )  # called from ObsChg edit view with ObsChg obj

    cslist = distances(oc).sort{|a,b| a[0] <=> b[0]}
    # return order by distance
    # synthesize name to include watt diff, distance
    # only return ones close enough
    cslist.count.times do |i|
      dis = cslist[i][0]
      cs = cslist[i][1]
      cslist[i][0] = "#{cs.name}(#{dis}:#{cs.wattdiff(oc)})"
      cslist[i][1] = cs.id
    end
    return cslist
  end

  def ChgSig.endrunchoices( oc )  # an ObsChg object

    trylist = ChgSig.distances oc
    csrlist = Array.new
    trylist.each do |dis, cs|
      next if cs.load_descs.empty? # a ChgSig may not have a LoadDesc
      cs.load_descs.each do |ld|  
        openruns=Run.find :all,
  :conditions => ['off_obs_chg_id is null and load_desc_id = ? and start_time < ?',
                  ld.id, oc.pwr_datum.dtime],
        :order => "start_time"
        openruns.each do |r|
          # add in distance from duration here
          csrlist.push [dis, r, cs]
        end
      end
    end
    csrlist.sort{|a,b| a[0] <=> b[0]}
  end

  def ChgSig.closest oc
    return oc.chg_sig.name if oc.chg_sig
    if oc.wattdiff > 0  # on event
      cslist = distances(oc).sort{|a,b| a[0] <=> b[0]}
      return "-" if cslist.empty?
      dis = cslist[0][0] # distance
      cs = cslist[0][1]  # the chgsig object
      return "?#{cs.name}(#{dis}:#{cs.wattdiff(oc)})"
    end
    # it's an off event
    csrlist = ChgSig.endrunchoices oc
    return "-" if csrlist.empty?
    dis = csrlist[0][0]
    r = csrlist[0][1]
    return "?#{r.load_desc.name}(#{dis})"
    
  end

  def ChgSig.close( oc, maxdist = 10 )
    cslist = distances(oc, maxdist).sort{|a,b| a[0] <=> b[0]}
    return nil if cslist.empty?
    cslist[0][1]  # the chgsig object
  end

  def ChgSig.onmatches( obschg )  # an ObsChg object
    if @@alist.empty?
      @@alist = ChgSig.all
debugger
    end

    wchg = obschg.wattdiff
    rchg = obschg.ramp
    cslist = @@alist.find_all {|s| wchg >= s.wonlow && wchg <= s.wonhigh &&
      rchg >= s.ronlow && rchg <= s.ronhigh}
    if cslist.empty?
      return nil
    elsif cslist.length == 1
      return cslist[0]
    end
    raise "more than one chgsig matched"
  end
end
