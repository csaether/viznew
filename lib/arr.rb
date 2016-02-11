class Arr
  def Arr.blockdist( a1, a2 )
    return nil if a1.length != a2.length
    bd = 0
    a1.length.times do |i|
      bd += (a1[i] - a2[i]).abs
    end
    return bd
  end

  def Arr.eucdist( a1, a2, s=0, e=nil )
    return nil if a1.length != a2.length
    e = a1.length - 1 if e.nil?
    return nil if s > e || e >= a1.length
    sqrsum = 0
    s.upto(e) do |i|
      d = (a1[i] - a2[i])
      sqrsum += d*d
    end
    return Math.sqrt sqrsum
  end

  def Arr.diff( a1, a2 )  # add r to a1 to get to a2
    c = a1.length
    return nil if c != a2.length
    r = Array.new( c )
    c.times do |i|
      r[i] = a2[i] - a1[i]
    end
    return r
  end

  def Arr.mul( a1, a2, con = 1 )
    c = a1.length
    return nil if c != a2.length
    r = Array.new( c )
    c.times do |i|
      r[i] = a1[i]*a2[i]*con
    end
    return r
  end

  def Arr.div( a1, a2 )
    c = a1.length
    return nil if c != a2.length
    r = Array.new( c )
    c.times do |i|
      r[i] = nil
      r[i] = a1[i]/a2[i] unless a2[i] == 0
    end
    return r
  end

  # average the values
  def Arr.avg( arrarr )
    n = arrarr.count
    return nil if n < 2
    c = arrarr[0].count
    r = Array.new( c )
    c.times{|i| r[i] = arrarr[0][i] }
    1.upto(n) do |j|
      return nil if arrarr[j].count != c
      c.times{ |i| r[i] += arrarr[j][i] }
    end
    c.times{ |i| r[i] /= n }
  end

  def Arr.tupcmp( a, b, i = 0 )
    if i == a.count || a[i] != b[i]
      return a[i] <=> b[i]
    end
    Arr.tupcmp( a, b, i + 1 )
  end
end
