require './app/models/package'

class Measurement < ApplicationRecord
  belongs_to :package

  def self.do_measurement
    t = DateTime.now.in_time_zone - 30
    p = Package.where('updated_at > ?', t)
    binding.pry
  end
end
