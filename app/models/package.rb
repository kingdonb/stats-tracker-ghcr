require 'pry'

class Package < ApplicationRecord
  belongs_to :repository
  has_one :github_org, through: :repository

  def run(k8s:, last_update:)
    # It's time to mark the Leaves as Ready
    #
    # binding.pry
    if updated_at < last_update
      touch
      save!
    end
  end
end
