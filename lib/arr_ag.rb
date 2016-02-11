class ArrAg
  attr_reader :arr

  # will deal with simple array, or array of arrays (each same size)

  def initialize( arg )
    # this is called with different type of arg depending on whether
    # we are creating a new one for the database, or the database
    # is creating from it's data.  Does that seem right?

    if arg.kind_of?(String)
#      @arr = Zlib::Inflate(arg).split(/,/).collect{|v| v.to_i}
      sarr = arg.split(/,/)
      rarr = sarr.collect do |v|
        if v.include? ?.
          v.to_f
        else
          v.to_i
        end
      end
      w = rarr.pop.to_i  # width of inner array is last element
      if w == 1
        @arr = rarr
      else
        @arr = Array.new()
        0.step( rarr.count - 1, w ) do |i|
          @arr.push rarr[i..i+w-1]
        end
      end
    elsif arg.kind_of?(Array)
      @arr = arg
    else
      @arr = []
    end
  end

  # what active record will call to get the value to store, apparently
  def arr_ag
#    Zlib::Deflate.deflate( @arr.join(',') )
    return nil if @arr.empty?
    w = 1
    if @arr[0].kind_of?(Array)
      w = @arr[0].count
    end

    @arr.join(',') + ',' + w.to_s
  end
end
