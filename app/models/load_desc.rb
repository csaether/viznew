# == Schema Information
# Schema version: 20111123043408
#
# Table name: load_descs
#
#  id         :integer         not null, primary key
#  avg_on     :integer
#  avg_off    :integer
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  short_duty :integer
#  long_duty  :integer
#

class LoadDesc < ActiveRecord::Base
  has_and_belongs_to_many :chg_sigs
  has_many :runs

  def wattdiff_part( obschg )
    wattdiff = obschg.wattdiff
    if obschg.chg_sig.load_descs.count == 1
      return wattdiff
    end

    nomtot=0
    lds=obschg.chg_sig.load_descs
    if wattdiff > 0
      lds.each{|ld| nomtot += ld.avg_on}
    else
      lds.each{|ld| nomtot -= ld.avg_off}
    end
    rat = avg_on.to_f/nomtot.to_f
    (rat*wattdiff).to_i
  rescue Exception => e  # really $!
    puts e
byebug
  end

  def dutydist( dursecs )
    low = short_duty.nil? ? dursecs : short_duty
    hi = long_duty.nil? ? dursecs : long_duty
    dd = 0.0
    if dursecs < low
      dif = low - dursecs
      drat = (dif/short_duty.to_f)*4
      dd = Math.exp drat
    elsif dursecs > hi
      dif = dursecs - hi
      drat = (dif/short_duty.to_f)*8
      dd = Math.exp drat
    end
    return dd
  end
end
