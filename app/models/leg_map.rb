# == Schema Information
# Schema version: 20111123043408
#
# Table name: leg_maps
#
#  id               :integer         not null, primary key
#  leg              :integer
#  voltchan         :integer
#  ampchan          :integer
#  raw_data_file_id :integer
#

class LegMap < ActiveRecord::Base

  belongs_to :raw_data_file
end
