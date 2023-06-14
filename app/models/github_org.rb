require 'pry'
require './app/models/package'

class GithubOrg < ApplicationRecord
  has_many :repositories
  has_many :packages, through: :repositories

  def run(k8s:, last_update:)
    t = last_update
    n = 0
    c = 0

    loop do
      # puts "###########Doing health check############"
      c = Package.where('updated_at > ?', t).count

      # Assume we get here within 5s (no, it's not really safe)
      break if c == package_count || n >= 7
      puts "########### fresh packages count: #{c} (expecting #{package_count}) #######"
      sleep 4
      n += 1
    end
    puts "########### final packages count: #{c} (expecting #{package_count}) #######"

    if c == package_count
      puts "########### cleaning up (OK!) #######"
      Measurement.do_measurement

      # Delete Sample project when we finished
      k8s.delete_project('fluxcd', 'default', {})
      touch
      save!
    else
      puts "########### c (#{c}) != package_count (#{package_count}) #######"
    end

    puts "########### this is the end of the GithubOrg#run Health Check method #######"
    # Watch all the Leaves, and when they
    # are ready, mark Project ready as well
  end
end
