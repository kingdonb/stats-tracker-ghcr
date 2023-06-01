require 'pry'

class Package < ApplicationRecord
  belongs_to :repository

  def run(k8s:, last_update:)
    # It's time to mark the Leaves as Ready
    #
    binding.pry
  end
end
