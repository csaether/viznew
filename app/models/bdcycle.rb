# == Schema Information
# Schema version: 20111123043408
#
# Table name: bdcycles
#
#  id               :integer         not null, primary key
#  raw_data_file_id :integer
#  cyclenum         :integer(16)
#  foffset          :integer(12)
#  samplecount      :integer
#

class Bdcycle < ActiveRecord::Base

  belongs_to :raw_data_file

  def get_avg_values( maxcnt = 300, pwrof2 = false )

    samps = samplecount*2  # min + max each
    avgeach = (samps/maxcnt).to_i
    return get_values avgeach, pwrof2
  end

  def get_values( samplestoaverage = 1, pwrof2 = true )
    fin = raw_data_file.open_burst_data
    fin.seek( foffset )

    ampvals = Array.new( samplecount )
    voltvals = Array.new( samplecount )
    samplecount.times do |i|
      sb = fin.read(6)
      sa = sb.unpack('s2')  # unpack two shorts
      ampvals[i] = sa[1].to_f
      voltvals[i] = sa[0].to_f
    end

    retcount = ampvals.count/samplestoaverage
    if pwrof2
      pwr2 = (Math.log(retcount)/Math.log(2)).to_i
      retcount = (Math.exp(pwr2*Math.log(2))).round
    end

    return ampvals, voltvals if (retcount == ampvals.count)

    retamps = Array.new(retcount)
    retvolts = Array.new(retcount)

    retcount.times do |ri|
      ampval = 0
      voltval = 0
      i = ri*samplestoaverage
      i.upto( i + samplestoaverage - 1 ) do |j|
        ampval += ampvals[j]
        voltval += voltvals[j]
      end
      retamps[ri] = ampval/samplestoaverage
      retvolts[ri] = voltval/samplestoaverage
    end

    return retamps, retvolts
  ensure
    fin.close unless fin.nil?
  end

  def get_values_v1( samplestoaverage = 1, pwrof2 = true )
    fin = raw_data_file.open_burst_data
    fin.seek( foffset )

    ampvals = Array.new( samplecount*2 )  # min + max for each sample
    voltvals = Array.new( samplecount*2 )
    0.step( (2*samplecount) - 1, 2 ) do |i|
      sb = fin.read(8)
      sa = sb.unpack('s4')  # unpack four shorts
      ampvals[i] = sa[0].to_f
      ampvals[i+1] = sa[1].to_f
      voltvals[i] = sa[2].to_f
      voltvals[i+1] = sa[3].to_f
    end

    retcount = ampvals.count/samplestoaverage
    if pwrof2
      pwr2 = (Math.log(retcount)/Math.log(2)).to_i
      retcount = (Math.exp(pwr2*Math.log(2))).round
    end

    return ampvals, voltvals if (retcount == ampvals.count)

    retamps = Array.new(retcount)
    retvolts = Array.new(retcount)

    retcount.times do |ri|
      ampval = 0
      voltval = 0
      i = ri*samplestoaverage
      i.upto( i + samplestoaverage - 1 ) do |j|
        ampval += ampvals[j]
        voltval += voltvals[j]
      end
      retamps[ri] = ampval/samplestoaverage
      retvolts[ri] = voltval/samplestoaverage
    end

    return retamps, retvolts
  ensure
    fin.close unless fin.nil?
  end

  def Bdcycle.get_range( begcyc, endcyc )
    rarr = Array.new 2, []
    begcyc.upto( endcyc ) do |cyc|
      bd = find_by_cyclenum cyc
      raise "no such cycle" if bd.nil?
      a = bd.get_values 1, false
      2.times{|i| rarr[i] += a[i]}
    end
    return rarr
  end

  def Bdcycle.realp_range( begcyc, endcyc, fudge = 10873 )
    ampvals, voltvals = get_range begcyc, endcyc
    pvals = Arr.mul ampvals, voltvals
    sum = 0
    pvals.each{ |v| sum += v }
    return sum/(ampvals.count*fudge)
  end

  def get_fft_slices( pointsperslice, stype = 'a', samplestoaverage = 1 )

    avals, vvals = get_values( samplestoaverage, false )
    vals = stype == 'a' ? avals : vvals

    acnt = (vals.count/pointsperslice).to_i
    fpps = vals.count/(acnt*1.0)

    retarr = []

=begin
    0.step( ((vals.count - pointsperslice)/pointsperslice).to_i*pointsperslice,
            pointsperslice ) do |i|
      retarr.push Cfft( vals.slice( i, pointsperslice ) )
=end
    acnt.times do |ei|
      retarr.push Cfft( vals.slice( (ei*fpps).to_i, pointsperslice ) )
    end
    return retarr
  end

  def realpwr( fudge = 10873 )

    ampvals, voltvals = get_values 1, false
    c = ampvals.count
    return nil if c != voltvals.count
    pvals = Arr.mul ampvals, voltvals
    sum = 0
    pvals.each { |v| sum += v }
    return sum/(c*fudge)
  end

  def reacpwr( fudge = 10873 )
    # use ampvals from quarter into this cycle, and into next,
    # to effect 90 degree phase shift
    bdp = Bdcycle.find_by_cyclenum(cyclenum + 1)
    return nil if bdp.nil?

    ampvals1, voltvals = get_values 1, false
    c = ampvals1.count
    return nil if c != voltvals.count
    ampvals2, toss = bdp.get_values 1, false
#    return nil if c != ampvals2.count

#    ampvals = ampvals0[(3*c)/4..(c-1)] + ampvals1[0..(3*c/4 - 1)]
    ampvals = ampvals1[(c/4)..(c-1)] + ampvals2[0..(c/4-1)]

    pvals = Arr.mul ampvals, voltvals
    sum = 0
    pvals.each { |v| sum += v }
    return sum/(c*fudge)
  end

  def reacpwr2( fudge = 10873 )
    ampvals1, voltvals = get_values 1, false
    c = ampvals1.count
    return nil if c != voltvals.count

    ampvals = ampvals1[(c/4)..(c-1)] + ampvals1[0..(c/4-1)]

    pvals = Arr.mul ampvals, voltvals
    sum = 0
    pvals.each { |v| sum += v }
    return sum/(c*fudge)
  end
end
