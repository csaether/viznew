class X
  def X.parsecs str
    a=str.split ':'
    s=0
    m=[1,60,60*60]
    3.times do |i|
      break if (v = a.pop).nil?
      s += m[i]*v.to_i
    end
    s == 0 ? nil : s
  end
end
