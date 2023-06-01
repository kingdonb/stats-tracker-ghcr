require 'pry'

class Package < ApplicationRecord
  belongs_to :repository

  def run(k8s)
    # binding.pry
  end
end
