# == Schema Information
# Schema version: 20111123043408
#
# Table name: fft_data
#
#  id       :integer         not null, primary key
#  cyclenum :integer(16)
#  ftype    :string(1)
#  fft_spec :binary
#

class FftDatum < ActiveRecord::Base
  composed_of :fft_spec, :class_name => 'FftSpec'

  def FftDatum.doburstdat(bname,  # base name, will add extension
             lowcyc = 0,  # lowest cycle to output
             hicyc = nil)  # highest cycle to output
debugger
    i = IO.sysopen(bname+'-burst.dat')
    fin = IO.open(i, 'rb')
    FftDatum.connection.execute('PRAGMA synchronous=0;')

    cycstodo = Array.new( 2*ObsChg.count )
    i = 0
    ObsChg.find(:all).each do |oc|
      cycstodo[i]=oc.precycnum
      i+=1
      cycstodo[i]=oc.postcycnum
      i+=1
    end
    nextcyctodo = cycstodo.shift
#    hicyc = lowcyc if hicyc.nil?
    cyci = nil
    docyc = false
    ampvals = []
    voltvals = []
    while (sb = fin.read(8))
      sa = sb.unpack('s4')
      if sa[0] == 0x7abc
        if sa[1] == 0x7abc && sa[2] == 0x7abc && sa[3] == 0x7abc
          sb = fin.read(8)
          break if sb.nil?
          # identified a new cycle - process the previous one, if any
          if docyc
            docyc = false
#            chk = FftDatum.find_all_by_cyclenum cyci
            
#            puts 'processing cycle ' + cyci.to_s
            ampfft = Cfft( ampvals )
            ampvals = []

            FftDatum.create! :cyclenum => cyci, :ftype => "A",
                :fft_spec => FftSpec.new(ampfft)

            voltfft = Cfft( voltvals )
            voltvals = []

            FftDatum.create! :cyclenum => cyci, :ftype => "V",
                :fft_spec => FftSpec.new(voltfft)

=begin
            @fout.puts cyci.to_s + ' fft, ffffffff, ffffffffff, fffffffff'
            ampfft.each_index do |i| 
              @fout.print ampvals[i].to_s + ','
              @fout.puts ampfft[i]
            end
=end
            ampfft = []
            voltfft = []
          end

          cyci = sb.unpack('Q')[0]
=begin
          docyc = true if cyci >= lowcyc
          docyc = false if hicyc && cyci > hicyc
          print 'skipping cycle ' unless docyc
          puts cyci
=end
          if nextcyctodo && cyci == nextcyctodo
            docyc = true
            puts 'doing' + cyci.to_s + ' with ' + cycstodo.count.to_s + ' left'
            nextcyctodo = cycstodo.shift
          end
#          next unless docyc
          next
        end
      end
      next unless docyc
      next if ampvals.count == 2048  # could base on size of input
## modified to average min/max, yielding half the samples
      ampvals.push( (sa[0].to_f + sa[1].to_f)/2.0 )
#      ampvals.push sa[1].to_f
      voltvals.push( (sa[2].to_f + sa[3].to_f)/2.0 )
#      voltvals.push sa[3].to_f
    end
    fin.close
#    @fout.close
  end

  def FftDatum.diff( c1, c2, t = 'A' )
    cd1 = FftDatum.find_by_cyclenum_and_ftype c1, t
    cd2 = FftDatum.find_by_cyclenum_and_ftype c2, t
    c = cd1.fft_spec.spec.count
    res = Array.new(c)

    c.times do |i|
      a = Array.new(2)
      a[0] = cd1.fft_spec.spec[i]
      a[1] = cd2.fft_spec.spec[i] - a[0]
      res[i] = a
    end
    res
  end

  def FftDatum.adiff( c1, c2, t = 'A' )
    cd1 = FftDatum.find_by_cyclenum_and_ftype c1, t
    cd2 = FftDatum.find_by_cyclenum_and_ftype c2, t
    c = cd1.fft_spec.spec.count
    res = Array.new(c)

    c.times do |i|
      d = cd1.fft_spec.spec[i]
      res[i] = d - cd2.fft_spec.spec[i]
    end
    res
  end

  def FftDatum.ratio( c1, c2, t = 'A' )
    diffa = FftDatum.diff c1, c2, t
    c = diffa.length
    rat = Array.new(c)

    0.upto( c - 1 ) do |i|
      val1 = diffa[i][0]
      val2 = val1 + diffa[i][1]
      rat[i] = val2/val1
    end
    rat
  end

  def FftDatum.mkhash( ffa )
    ah={}
    vh={}
    ffa.each do |a|
      if a.ftype == 'A'
        ah[a.cyclenum] = a.fft_spec.spec
      else
        vh[a.cyclenum] = a.fft_spec.spec
      end
    end
    return ah, vh
  end
end
