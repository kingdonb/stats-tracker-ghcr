require 'active_record'
require './app/models/application_record'
require './app/models/package'
require './app/models/package'

require 'pg'
require 'dotenv'

class Measurement < ApplicationRecord
  belongs_to :package

  def self.call
    database_init

    gho = GithubOrg.find_by(name: 'fluxcd')

    t = DateTime.now.in_time_zone - 30
    n = 0
    c = 0

    loop do
      # puts "###########Doing health check############"
      c = Package.where('updated_at > ?', t).count

      # Assume we get here within 5s (no, it's not really safe)
      break if c == gho.package_count || n >= 3
      puts "########### fresh packages count: #{c} (expecting #{gho.package_count}) #######"
      sleep 10
      n += 1
    end
    puts "########### final packages count: #{c} (expecting #{gho.package_count}) #######"

    if c == gho.package_count
      puts "########### cleaning up (OK!) #######"
      Measurement.do_measurement

      # Delete Sample project when we finished
      k8s.delete_project('fluxcd', 'default', {})
      touch
      save!
    else
      puts "########### c (#{c}) != package_count (#{gho.package_count}) #######"
    end

    puts "########### this is the end of the GithubOrg#run Health Check method #######"
    do_measurement
  end

  def self.database_init
    # Load DATABASE_PASSWORD into env
    Dotenv.load '.env.local'

    # TODO: make this parse or reuse the connection from database.yml
    ActiveRecord::Base.establish_connection(
      adapter:  'postgresql', # or 'postgresql' or 'sqlite3'
      database: 'dlcounts',
      username: 'thecount',
      password: ENV["GRAFANA_DOWNLOADS_APP_DATABASE_PASSWORD"],
      host:     'dl-count-db.turkey.local'
    )
  end

  def self.do_measurement
    t = DateTime.now.in_time_zone - 30
    p = Package.where('updated_at > ?', t)
    binding.pry
  end
end
