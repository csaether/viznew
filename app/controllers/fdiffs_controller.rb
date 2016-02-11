class FdiffsController < ApplicationController

  def index

  end

  def watts

    low = params[:low].to_i
    high = params[:high].to_i
    low = nil if high.nil?  # either both or none
    fname = 'all'
    cond = []
    if low
      if high < low
        t = low
        low = high
        high = t
      end
      cond = ['wattdiff >= ? and wattdiff <= ?', low, high]
      fname = low.to_s + '-' + high.to_s
    end
    fname += '.csv'
    oca = ObsChg.find :all, :order => 'wattdiff', :conditions => cond

    cnt = FftDatum.find(:first).fft_spec.spec.count

    hdr = Array.new( 4 + cnt )
    hdr[0] = 'Name'
    hdr[1] = 'Change'
    hdr[2] = 'Difftype'
    hdr[3] = 'Eucdist'
    4.upto(cnt+4-1) do |i|
      hdr[i] = ((i-4)*60).to_s + 'Hz'
    end

    attrs = ['temp', 0, 0, 0]
    data1 = nil
    csvdata = FasterCSV.generate do |line|
      line << hdr

      oca.each do |oc|
        attrs[1] = oc.wattdiff
        data = FftDatum.adiff( oc.precycnum, oc.postcycnum )
        if data1
          attrs[3] = Arr.eucdist data, data1
        else
          data1 = data
        end
        line << attrs + data
      end

    end

    send_data csvdata, :type => :csv, :filename => fname
  end

private

end
