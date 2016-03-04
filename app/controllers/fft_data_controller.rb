class FftDataController < ApplicationController
  def index

    respond_to do |wants|
      wants.html do
        @fft_data = FftDatum.paginate :page => params[:page]
      end
      wants.csv do
        @fft_data = FftDatum.all
      end
    end
  end

  def csv

    @fft_data = FftDatum.all
    cnt = @fft_data[0].fft_spec.spec.length # better be the same
    freqs = Array.new(cnt)
    (cnt - 1).times do |i|
      freqs[i] = i*60
    end
    csvdata = FasterCSV.generate do |csv|
      csv << ['cycle', 'type' ] + freqs

      @fft_data.each do |fd|
        csv << [fd.cyclenum, fd.ftype] + fd.fft_spec.spec
      end
    end

    send_data csvdata, :type => :csv, :filename => 'lowhigh.csv'
  end

end
