# == Schema Information
# Schema version: 20111123043408
#
# Table name: obs_chgs
#
#  id           :integer         not null, primary key
#  wattdiff     :integer
#  ramp         :float
#  pwr_datum_id :integer
#  precycnum    :integer(16)
#  postcycnum   :integer(16)
#  chg_sig_id   :integer
#  training     :boolean
#  vardiff      :integer
#

class ObsChg < ActiveRecord::Base
  belongs_to :pwr_datum
  belongs_to :chg_sig
  has_many :cyc_data
  has_many :run_ons, :class_name => "Run", :foreign_key => :on_obs_chg_id
  has_many :run_offs, :class_name => "Run", :foreign_key => :off_obs_chg_id

  def self.per_page
    20
  end

  def trancycs
    postcycnum - precycnum - 1
  end

  def zapRuns
    run_ons.each do |r|
      r.destroy
    end
    run_offs.each do |r|
      r.destroy
    end
  end

  def cname
    return '?' if chg_sig.nil?
    chg_sig.name + (wattdiff > 0 ? 'On' : 'Off')
  end
end
