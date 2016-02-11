# == Schema Information
# Schema version: 20111123043408
#
# Table name: cyc_data
#
#  id         :integer         not null, primary key
#  watts      :integer
#  obs_chg_id :integer
#  vars       :integer
#  leg        :integer
#

class CycDatum < ActiveRecord::Base
  belongs_to :obs_chg
end
