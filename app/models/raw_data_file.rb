# == Schema Information
# Schema version: 20111123043408
#
# Table name: raw_data_files
#
#  id                   :integer         not null, primary key
#  bname                :string(255)
#  base_cyclenum        :integer(16)     default(0)
#  created_at           :datetime
#  updated_at           :datetime
#  samps_per_half_cycle :integer
#  data_channels        :integer
#

class RawDataFile < ActiveRecord::Base

  has_many :leg_maps
  has_many :bdcycles

  def open_burst_data
    i = IO.sysopen(bname+'-burst.dat')
    IO.open(i, 'rb')
  end

  def process_burst_data

    fin = open_burst_data
    sb = fin.read(4)
    vmagic = sb.unpack('s2')
    fin.close
    if (vmagic[0] & 0xfff0) == 0x8ab0
      return process_burst_data_v2
    end

    return process_burst_data_v1  
  end


  def process_burst_data_v2

    fin = open_burst_data
    Bdcycle.connection.execute('PRAGMA synchronous=0;')

    lastbd = Bdcycle.last
    hicycnum = lastbd.nil? ? 0 : lastbd.cyclenum

    cycnum = nil
    lastcycnum = nil
    cycstart = nil
    readsize = 4  # for first read, will be 2*numchans
    cycsamples = nil
    while (sb = fin.read(readsize))  # pos is updated after each read
      sa = sb.unpack('s2')
      if (sa[0] & 0xfff0) == 0x8ab0 && (sa[1] & 0xfff0) == 0x8ab0
        # seen the magic marker, cycle number is next
        # end of samples for current cycle preceded last read
        fin.seek( -(readsize - 4), IO::SEEK_CUR )  # otherwise cycle number misaligned
        readsize = 2*(sa[0] & 0xf) if cycstart.nil?
        cycsamples = (fin.pos - 4 - cycstart)/readsize unless cycstart.nil?

        sb = fin.read(8)  # the next cycle number
        raise "ending magic with no cycle?" if sb.nil?

        unless cycnum.nil? || (cycnum <= hicycnum)
          #            puts cycnum.to_s + ', ' + cycstart.to_s + ', ' + cycsamples.to_s
          Bdcycle.create! :raw_data_file_id => self.id,
          :cyclenum => cycnum, :foffset => cycstart,
          :samplecount => cycsamples
          if samps_per_half_cycle.nil?
            self.samps_per_half_cycle = cycsamples/2
            self.save!
          end
        end

        # position is now start of cycle data for next cycle
        cycstart = fin.pos
=begin
           if cycnum.nil?  # nil first time through

             chkcyc = sb.unpack('Q')[0]
             chkcyc += base_cyclenum
             bd = Bdcycle.find_by_cyclenum chkcyc
             return unless bd.nil?  # TODO: raise exception?
           end
=end
        cycnum = sb.unpack('Q')[0]
        cycnum += base_cyclenum

#          next  -  uncomment if code added to do anything with data
      end  # of got a new cycle
    end
    # one final cycle unless no cycles found
    return if cycnum.nil?
    cycsamples = (fin.pos - cycstart)/readsize
#    puts cycnum.to_s + ', ' + cycstart.to_s + ', ' + cycsamples.to_s
    Bdcycle.create! :raw_data_file_id => self.id,
      :cyclenum => cycnum, :foffset => cycstart,
      :samplecount => cycsamples

  ensure
    fin.close unless fin.nil?
  end

  def process_events
    PwrDatum.importevents( bname, base_cyclenum )
  end

  def add_cycles_only
    PwrDatum.importevents( bname, base_cyclenum, true )
  end

  def process_burst_data_v1

    fin = open_burst_data
    Bdcycle.connection.execute('PRAGMA synchronous=0;')

    lastbd = Bdcycle.last
    hicycnum = lastbd.nil? ? 0 : lastbd.cyclenum

    cycnum = nil
    lastcycnum = nil
    cycstart = nil
    cycsamples = nil
    while (sb = fin.read(8))  # pos is updated after each read
      sa = sb.unpack('s4')
      if sa[0] == 0x7abc
        if sa[1] == 0x7abc && sa[2] == 0x7abc && sa[3] == 0x7abc
          # seen the magic marker, cycle number is next
          # end of samples for current cycle preceded last read
          cycsamples = (fin.pos - 8 - cycstart)/8 unless cycstart.nil?

          sb = fin.read(8)
          raise "ending magic with no cycle?" if sb.nil?

          unless cycnum.nil? || (cycnum <= hicycnum)
#            puts cycnum.to_s + ', ' + cycstart.to_s + ', ' + cycsamples.to_s
            Bdcycle.create! :raw_data_file_id => self.id,
              :cyclenum => cycnum, :foffset => cycstart,
              :samplecount => cycsamples
            if samps_per_half_cycle.nil?
              self.samps_per_half_cycle = cycsamples
              self.save!
            end
          end

          # position is now start of cycle data for next cycle
          cycstart = fin.pos
=begin
          if cycnum.nil?  # nil first time through

            chkcyc = sb.unpack('Q')[0]
            chkcyc += base_cyclenum
            bd = Bdcycle.find_by_cyclenum chkcyc
            return unless bd.nil?  # TODO: raise exception?
          end
=end
          cycnum = sb.unpack('Q')[0]
          cycnum += base_cyclenum

#          next  -  uncomment if code added to do anything with data
        end  # of got a new cycle
      end
    end
    # one final cycle unless no cycles found
    return if cycnum.nil?
    cycsamples = (fin.pos - cycstart)/8
#    puts cycnum.to_s + ', ' + cycstart.to_s + ', ' + cycsamples.to_s
    Bdcycle.create! :raw_data_file_id => self.id,
      :cyclenum => cycnum, :foffset => cycstart,
      :samplecount => cycsamples

  ensure
    fin.close unless fin.nil?
  end
end
