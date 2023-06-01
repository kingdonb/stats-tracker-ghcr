require 'pry'

class Repository < ApplicationRecord
  belongs_to :github_org

  def run(k8s)
    binding.pry
  end
end
