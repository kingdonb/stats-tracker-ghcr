require 'pry'

class GithubOrg < ApplicationRecord
  def run(k8s)
    binding.pry
  end
end
