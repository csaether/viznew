class Clu
  def Clu.gravity( valplusarr, maxdpcnt = 7.0, scalefactor = 7.0 )
=begin
  takes an array of arrays where the first element of each is
  the value to compute gravity for.  Returns an array sorted by the 
  first value, the computed gravity, then an array of arrays of the remaining
  elements for the given value
  so for an array of [ [x, ...], [y, ...] ... ] we look at x to sort
  and calculate.
  return array for each unique value, followed by gravity sum, then
  density (sum/count), then an array of all elements within range for the
  given value, minus the sort value.
=end
    sortvalplus = valplusarr.sort{|a,b| a[0] <=> b[0]}
    totnum = sortvalplus.count
    ecount = sortvalplus[0].count  # how many elements per element...

    ilow = 0
    ihi = 0
    prevtval = nil
    gravitiesplus = []

    totnum.times do |i|
      tval = sortvalplus[i][0]
      # always the same delta range set for a given value, no need to calc
      if prevtval == tval
#        gravitiesplus[-1][2].push sortvalplus[i][1...ecount]
        next
      end
      prevtval = tval
      fardist = ((tval*maxdpcnt)/100.0).abs  # max delta from here
      minval = tval - fardist  # minimum value in range
      j = nil
      ilow.upto(totnum - 1) do |j|  # start from previous low index
        break if sortvalplus[j][0] >= minval
      end
      ilow = j
      maxval = tval + fardist  # high value for this range
      ihi.upto(totnum - 1) do |j|  # start from previous high index
        break if sortvalplus[j][0] > maxval
      end
      ihi = j - 1
      ihi  = j if sortvalplus[j][0] <= maxval
=begin
  at this point we have the range of values within maxdpcnt identified
  by ilow and ihi
=end
      gsum = 0.0

      sortvalplus[ilow..ihi].each do |e|
        adist = (e[0] - tval).to_f.abs  # absolute val diff
        onedist = adist/fardist  # scale to one
        scaledist = onedist*scalefactor  # then times scale factor
        scaledist = 1.0 if scaledist < 1.0  # avoid singlularity next

        gsum += 1.0/(scaledist*scaledist)
      end
      gravitiesplus.push [  tval, gsum, gsum/(ihi - ilow + 1),
                           sortvalplus[ilow..ihi] ]
    end
    return gravitiesplus
  end

  def Clu.grav2( obschgarr, maxdpcnt = 7.0, scalefactor = 7.0 )
    sobs=obschgarr.sort{|a,b| a.wattdiff <=> b.wattdiff}
    totnum = sobs.count
    gvals = []  # [wattdiff, vardiff, gsum, count]
    ilow = 0
    ihi = 0
debugger
    # walk through changes in wattdiff order
    # for each, find a set within a percent change of candidate
    totnum.times do |i|
      twval = sobs[i].wattdiff  # test watt diff val
      farwdist = ((twval*maxdpcnt)/100.0).abs  # far end of range considered
      minwval = twval - farwdist  # minimum diff this range
      j = nil
      ilow.upto(totnum - 1) do |j|  # start from previous low index
        break if sobs[j].wattdiff >= minwval  # start for this test val
      end
      ilow = j
      maxwval = twval + farwdist  # hi end of range for this test val
      ihi.upto(totnum - 1) do |j|  # again, start from previous high
        break if sobs[j].wattdiff > maxwval  # break when beyond this limit
      end
      ihi = j - 1 # one before break is end of range
      ihi  = j if sobs[j].wattdiff <= maxwval # check for end case
=begin
  at this point we have the range of values within maxdpcnt identified
  by ilow and ihi
  for each change, select the subset that also have vardiffs within range, then
  calculate a combined gravity including both
=end
      varval = sobs[i].vardiff
      farvar = ((varval*maxdpcnt)/100.0).abs
      farvar = 1.0 if farvar < 1.0
      sobs2 = sobs[ilow..ihi].each.select do |oc|
        vadist = (oc.vardiff - varval).to_f.abs
        vadist <= farvar
      end

      gsum = 0.0
#      puts "twval " + twval.to_s
      sobs2.each do |oc|
        wadist = (oc.wattdiff - twval).to_f.abs  # absolute wattdiff dist
        wonedist = wadist/farwdist # scale to one
        wscaledist = wonedist*scalefactor  # and to scale factor
        wscaledist = 1.0 if wscaledist < 1.0  # avoid close to zero

        vadist = (oc.vardiff - varval).to_f.abs # aboslute vardiff dist
        vonedist = vadist/farvar  # scaled to one
        vscaledist = vonedist*scalefactor # and to scale factor
        vscaledist = 1.0 if vscaledist < 1.0  # avoid singularity later

#        puts " v: " + oc.wattdiff.to_s + ", adist: " + adist.to_s + ", scaled: " + scaledist.to_s
        gsum += 1.0/(wscaledist*wscaledist) + 1.0/(vscaledist*vscaledist)
      end
      gsum1 = (gsum * 10).to_i/10.0
      gvals.push [twval, varval, sobs2.count, gsum1]
    end
    return gvals
  end

  def Clu.grav3( obschgarr, maxdpcnt = 7.0, scalefactor = 7.0 )
    sobs=obschgarr.sort{|a,b| a.wattdiff <=> b.wattdiff}
    totnum = sobs.count
    gvals = []  # [wattdiff, wattgrav, count, [ [vardiff, vargrav]...] ]
    ilow = 0
    ihi = 0
    lastwattdiff = nil

    # walk through changes in wattdiff order
    # for each, find a set within a percent change of candidate
    totnum.times do |i|
      twval = sobs[i].wattdiff  # test watt diff val
      # always the same delta range set for a given value, no need to calc
      next if lastwattdiff == twval
      lastwattdiff = twval
      farwdist = ((twval*maxdpcnt)/100.0).abs  # far end of range considered
      minwval = twval - farwdist  # minimum diff this range
      j = nil
      ilow.upto(totnum - 1) do |j|  # start from previous low index
        break if sobs[j].wattdiff >= minwval  # start for this test val
      end
      ilow = j
      maxwval = twval + farwdist  # hi end of range for this test val
      ihi.upto(totnum - 1) do |j|  # again, start from previous high
        break if sobs[j].wattdiff > maxwval  # break when beyond this limit
      end
      ihi = j - 1 # one before break is end of range
      ihi  = j if sobs[j].wattdiff <= maxwval # check for end case
=begin
  at this point we have the range of values within maxdpcnt identified
  by ilow and ihi
=end

      wgsum = 0.0  # wattdiff gravity from test val at center of range
#      puts "twval " + twval.to_s
      sobs[ilow..ihi].each do |oc|
        wadist = (oc.wattdiff - twval).to_f.abs  # absolute wattdiff dist
        wonedist = wadist/farwdist # scale to one
        wscaledist = wonedist*scalefactor  # and to scale factor
        wscaledist = 1.0 if wscaledist < 1.0  # avoid close to zero

#        puts " v: " + oc.wattdiff.to_s + ", adist: " + adist.to_s + ", scaled: " + scaledist.to_s
        wgsum += 1.0/(wscaledist*wscaledist)
      end
      wgsum1 = (wgsum * 10.0).to_i/10.0

      varvals = sobs[ilow..ihi].collect{|oc| oc.vardiff}
      vvs = varvals.sort
      # now do a set of var gravities and find the peaks
      ivlow = 0
      ivhi = 0
      vgravs = Array.new( vvs.count )
      vvs.count.times do |i|
        varval = vvs[i]
        farvar = 2.0 * ((varval*maxdpcnt)/100.0).abs
        farvar = 1.0 if farvar < 1.0
        minvval = varval - farvar
        j = nil
        ivlow.upto( vvs.count - 1 ) do |j|
          break if vvs[j] >= minvval
        end
        ivlow = j
        maxvval = varval + farvar
        ivhi.upto( vvs.count - 1 ) do |j|
          break if vvs[j] > maxvval
        end
        ivhi = j - 1  # one before break still in range
        ivhi = j if vvs[j] <= maxvval  # end case

        vgsum = 0.0
        vvs[ivlow..ivhi].each do |vv|
          vadist = (vv -  varval).to_f.abs # aboslute vardiff dist
          vonedist = vadist/farvar  # scaled to one
          vscaledist = vonedist*scalefactor # and to scale factor
          vscaledist = 1.0 if vscaledist < 1.0  # avoid singularity later

          vgsum += 1.0/(vscaledist*vscaledist)
        end
        vgravs[i] = [ varval, ivhi - ivlow + 1, (vgsum*10.0).to_i/10.0 ]
      end
#      vgpeaks = Clu.peaks( vgravs, 2 )
      vgpeaks = vgravs # if vgpeaks.empty?
      gvals.push [twval, wgsum1, vvs.count, vgpeaks]
    end
    return gvals
  end

  def Clu.peaks( arr, ix = nil )
    retarr = []
    return retarr if arr.count < 3
    preval = ix.nil? ? arr[0] : arr[0][ix]
    val = ix.nil? ? arr[1] : arr[1][ix]
    retarr.push( arr[0] ) if preval > val
    2.upto( arr.count - 1 ) do |i|
      nextval = ix.nil? ? arr[i] : arr[i][ix]
      retarr.push( arr[i - 1] ) if val > preval && val > nextval
      next if val == nextval
      preval = val
      val = nextval
    end
    retarr.push( arr[-1] ) if val > preval  # end case
    return retarr
  end

  def Clu.minertiad( valplusarr, maxdpcnt = 7.0, scalefactor = 7.0 )
=begin
  takes an array of arrays where the first element of each is
  the value to compute the inertial density around.
  Returns an array sorted by the 
  first value, the inertial density, then an array of arrays of the remaining
  elements for the given value
  so for an array of [ [x, ...], [y, ...] ... ] we look at x to sort
  and calculate.
  return array for each unique value, followed by inertial
  density (sum/count), then an array of all elements within range for the
  given value, minus the sort value.
=end
    sortvalplus = valplusarr.sort{|a,b| a[0] <=> b[0]}
    totnum = sortvalplus.count
    ecount = sortvalplus[0].count  # how many elements per element...

    ilow = 0
    ihi = 0
    prevtval = nil
    minertiasplus = []

    totnum.times do |i|
=begin
  we're keeping track of indices into the sorted array for the lower
  and upper values within the delta range.  this next section will
  update those values.
=end
      tval = sortvalplus[i][0]  # our center (target) value
      # always the same delta range set for a given value, no need to calc
      if prevtval == tval
        next
      end
      prevtval = tval
      fardist = ((tval*maxdpcnt)/100.0).abs  # max delta from here
      fardist = 10 if fardist < 10
      minval = tval - fardist  # minimum value in range
      j = nil
      ilow.upto(totnum - 1) do |j|  # start from previous low index
        break if sortvalplus[j][0] >= minval
      end
      ilow = j
      maxval = tval + fardist  # high value for this range
      ihi.upto(totnum - 1) do |j|  # start from previous high index
        break if sortvalplus[j][0] > maxval
      end
      ihi = j - 1
      ihi  = j if sortvalplus[j][0] <= maxval
=begin
  at this point we have the range of values within maxdpcnt identified
  by ilow and ihi
=end
      minertiasum = 0.0

      sortvalplus[ilow..ihi].each do |e|
        adist = (e[0] - tval).to_f.abs  # absolute val diff
        onedist = adist/fardist  # scale to one
        scaledist = onedist*scalefactor  # then times scale factor

        minertiasum += (scaledist*scaledist) + 0.1
      end
      count = ihi - ilow + 1
      next if count == 1
#      minertiasplus.push [  tval, minertiasum/count,
      inertia = (10*count*count/minertiasum).to_i/10.0
      minertiasplus.push [  tval, inertia,
                           sortvalplus[ilow..ihi] ]
    end
    return minertiasplus
  end

  def Clu.valleys( arr, ix = nil )

    retarr = []
    return retarr if arr.count < 3
    preval = ix.nil? ? arr[0] : arr[0][ix]
    val = ix.nil? ? arr[1] : arr[1][ix]
    retarr.push( arr[0] ) if preval <= val
    2.upto( arr.count - 1 ) do |i|
      nextval = ix.nil? ? arr[i] : arr[i][ix]
      retarr.push( arr[i - 1] ) if val <= preval && val <= nextval
      preval = val
      next if val == nextval
      val = nextval
    end
    retarr.push( arr[-1] ) if val <= preval  # end case
    return retarr
  end
end
