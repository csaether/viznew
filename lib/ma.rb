class Ma
  def Ma.stdev( vals )
    return nil, nil, nil if vals.count < 2
    tot = 0.0
    vals.each{ |v| tot += v }
    mean = tot/vals.count
    totsqdiff = 0.0
    vals.each do |v|
      d = (v - mean).abs
      totsqdiff += Math.exp( 2*Math.log( d ) ) unless d == 0
    end
    dev = Math.sqrt( totsqdiff/(vals.count - 1) )  # sample estimator
    return mean, dev, vals.count
  end

  def Ma.swin( vals, basedelta )
    return nil if vals.count < 10
    # slide window over sorted(?) values
debugger
    firstval = vals[0].to_i
    lastval = vals[-1].to_i
    return if lastval < firstval
    retA=[]
    loi = 0
    hii = 0
    cloi = 0
    chii = 0
    maxi = vals.count - 1
    (firstval).upto(lastval) do |cv|   # center value
      rat=cv.abs/75
      rat = 1.0 if rat < 1.0
      delta = basedelta*(Math.log(rat)*0.75 + 1)
      lowv = cv - delta
      hiv = cv + delta
      clowv = cv - delta/3
      chiv = cv + delta/3
      while vals[loi] < lowv && loi < maxi : loi += 1 end
      while vals[hii] < hiv && hii < maxi
        break if vals[hii+1] > hiv
        hii += 1
      end
      next if vals[loi] > hiv
      next if hii == loi
      next unless vals[loi..hii].include? cv
      mean, dev, count = Ma.stdev vals[loi..hii]
      retA.push [count, cv, (mean-cv).to_i, delta.to_i]
      while vals[cloi] < clowv && cloi < maxi : cloi += 1 end
      while vals[chii] < chiv && chii < maxi
        break if vals[chii+1] > chiv
        chii += 1
      end
      next if vals[cloi] > chiv
      next if chii == cloi
      cmean, cdev, ccount = Ma.stdev vals[cloi..chii]
      retA[-1] += [ccount, (cmean-cv).to_i]
#      print (mean-cv).to_i.to_s + ', ' + dev.to_i.to_s + ', ' + count.to_s + ', ' + cv.to_s
#      puts ', ' + delta.to_i.to_s  # ", " + vals[loi].to_s + ', ' + vals[hii].to_s
    end
    return retA
  end
end
