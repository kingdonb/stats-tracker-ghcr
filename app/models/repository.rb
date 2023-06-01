require 'pry'

class Repository < ApplicationRecord
  has_many :packages
  belongs_to :github_org

  def run(k8s:, last_update:)
    # There is no Repository CRD so I think
    # we could ignore this event except, ...
    #
    # Let's mark the Repository as updated:
    if updated_at < last_update
      touch
      save!
    end
  end
end
