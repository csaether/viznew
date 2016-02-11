class FftSpec
  attr_reader :spec

  def initialize( spec )
    if spec.kind_of?(String)
      @spec = Zlib::Inflate.inflate(spec).split(/,/).collect{|v| v.to_f}
    elsif spec.kind_of?(Array)
      @spec = spec.collect{|v| (v.to_f*100).to_i/100.0}
    else
      @spec = []
    end
  end

  def fft_spec
    Zlib::Deflate.deflate( @spec.join(',') )
  end
end
