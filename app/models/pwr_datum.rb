# == Schema Information
# Schema version: 20111123043408
#
# Table name: pwr_data
#
#  id        :integer         not null, primary key
#  watts     :integer
#  dtime     :datetime
#  addcycles :integer
#  vars      :integer
#

class PwrDatum < ActiveRecord::Base
  has_one :obs_chg

#  def PwrDatum.importevents( bname, basecyc = 0, stime = nil, etime = nil )
  def PwrDatum.importevents( bname,
#                             countpercycle, # to adjust lag, half real rate
                             basecyc = 0,
                             addcycdataonly = false )
    fname = bname + "-e.csv"
    f = File.new( fname, "r" )
    tscyc = 0
    tssecs = 0
#    tsusecs = 0
    endcyc = nil
    endval = nil
    endvar = nil
    begcyc = nil
    begval = nil
    begvar = nil
    chgvals = []
    chgvars = []
    rampratio = 0
    done = false
    startpd = nil
    lastochg = nil
    gotcycdata = false
#    countpercycle = 1000000 if countpercycle.nil?
byebug
    begin
      pd = PwrDatum.find :last  # effectively ordered by dtime
    rescue
      pd = nil
    end

    stime = nil
    unless pd.nil?
      stime = pd.dtime - 16 # back up before last possible timestamp
    end

    PwrDatum.connection.execute('PRAGMA synchronous=0;')
    CycDatum.connection.execute('PRAGMA synchronous=0;')
    count = 0
    skip = true  # need to see an initial timestamp before any events
    f.each do |a|
      pa = a.split(",")  # [0]code, [1]cycnum, {[2]watts, [3]vars}..., []dtime
      cycnum = pa[1].to_i + basecyc
      wattval=varval=0
      wattlegvals = []
      varlegvals = []
=begin
  a bit obscure.  at the moment there is always two values per line
  after cycle number.  only "T" has a date at the end, so take away
  the non-value elements (code, cycnum) and divide the remainder by
  two to get the number of legs.  One more if the date is there will
  not change the result.
=end
      ((pa.count-2)/2).times do |i|
        wattlegvals.push pa[i*2+2].to_i
        wattval += wattlegvals[-1]
        varlegvals.push pa[i*2+3].to_i
        varval += varlegvals[-1]
      end

      if pa[0] == "T"  # && !pa[-1].nil? - when is there none?
        tim = Time.parse pa[-1]
        tscyc = cycnum
        tssecs = tim.tv_sec
        if stime && (tim <= stime)
          next
        else
          skip = false
        end
        if false  #  etime && tim >= etime
          done = true
          next
        end
#        tsusecs = tim.tv_usec

        unless addcycdataonly
          unless startpd.nil? && PwrDatum.find_by_dtime(tim.gmtime)
            PwrDatum.create! :watts => wattval, :dtime => tim,
                           :vars => varval
          end
        end

      elsif skip
        next  # keep skipping until initial timestamp seen
      elsif pa[0] == "E"
        endcyc = cycnum
        endval = wattval
        endvar = varval
        chgvals = []
        chgvars = []
      elsif pa[0] == "S"
        # start of a new run event, create a pwr data point
        # the observed change record will be created and
        # partially filled in now, then updated after the 
        # cycle data for the transition is processed

        begcyc = cycnum
        begval = wattval
        begvar = varval
        diff = begval - endval
        cycsafterts = cycnum - tscyc
        secsafterts = cycsafterts/60
        tim = Time.at( tssecs+secsafterts, ((cycsafterts % 60)*1000000)/60 )

        addcyc = cycsafterts % 60
        if startpd.nil?  # have not created one yet
          haveit = PwrDatum.find_by_dtime_and_addcycles tim.gmtime, addcyc
          next if haveit
        end
        if addcycdataonly
          startpd = PwrDatum.find_by_dtime_and_addcycles tim.gmtime, addcyc
          lastochg = startpd.obs_chg
          if lastochg.precycnum.nil? && !addcycdataonly
            puts 'updating ' + startpd.dtime.to_s + ', ' + addcyc.to_s
            lastochg.precycnum = endcyc
            lastochg.postcycnum = begcyc
            lastochg.save!
          end
          lastochg = nil
        else
          startpd = PwrDatum.create! :watts => begval, :vars => varval,
          :dtime => tim, :addcycles => addcyc

          lastochg = ObsChg.create! :wattdiff => (begval - endval ),
          :vardiff => (begvar - endvar),  # /countpercycle.to_f*360,
          :pwr_datum => startpd, :precycnum => endcyc, :postcycnum => begcyc
        end
=begin
this made some sense if we are always checking to see if pwr_datum
exists, but this is not the case now.  this is also slow.
        if startpd.obs_chg.cyc_data.count == (25 + begcyc - endcyc)
          gotcycdata = true
        else
          gotcycdata = false
        end
=end
      elsif pa[0] == "C"

#        next if gotcycdata
        next if startpd.nil?
        wattlegvals.count.times do |leg|
          CycDatum.create! :watts => wattlegvals[leg],
                         :obs_chg => startpd.obs_chg,
                         :vars => varlegvals[leg],
                         :leg => leg
        end
        next if addcycdataonly

        if cycnum >= endcyc && cycnum <=begcyc
          chgvals << wattval
          chgvars << varval
        end
        # calculate ramp based on runtime determination of end, start
        if cycnum == begcyc
          chg = begval - endval
          halfway = endval + chg/2
          rampratio = 0.0
          i = 0
          while (i += 1) < chgvals.length - 1 do
            val = chgvals[i]
            halfdist = val - halfway
            valdist = nil
            if halfdist >= 0  # above halfway
              if chg >= 0  # going up
                valdist = val - begval # from endpoint of transition
              else  # going down
                valdist = endval - val # from start of transition
              end
            else  # below halfway
              if chg >= 0  # going up
                valdist = endval - val  # from tran start
              else
                valdist = val - begval
              end                
            end
            if chg.to_f == 0.0
byebug
              chg = 1
            end
            rampval = valdist.to_f/chg.to_f
            rampratio += rampval
#            puts "   " + rampval.to_s
          end

          if lastochg
            lastochg.ramp = rampratio
            lastochg.save!
            puts chg.to_s + ",    " + rampratio.to_s + ",  " + endcyc.to_s
          end
#          done = (count += 1) > max
        end # of cycnum == begcyc
      end  # of pa[0] == "C"
      break if done
    end

    f.close
  end
end
