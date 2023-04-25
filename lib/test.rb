require 'gammo'
require 'open-uri'
require './my_wasmer'

BIG_HONKIN_SELECTOR = "#repo-content-turbo-frame > div > div > div > div.d-flex.flex-column.flex-md-row.mt-n1.mt-2.gutter-condensed.gutter-lg.flex-column > div.col-12.col-md-3.flex-shrink-0 > div:nth-child(3) > div.container-lg.my-3.d-flex.clearfix > div.lh-condensed.d-flex.flex-column.flex-items-baseline.pr-1".freeze

def html
  @html ||= http_client_read
end

def gammo_current_download_count(html)
  g = Gammo.new(html.read)
  h = g.parse

  t = h.css(BIG_HONKIN_SELECTOR)
  u = t[0].children
  v = u[3].attributes["title"]
end

def noko_current_download_count(html)
  h = Nokogiri::HTML(html)

  t = h.css(BIG_HONKIN_SELECTOR)
  u = t[0].children
  v = u[3].attributes["title"].value
end

def get_current_stat_with_time
  client = Proc.new do |url|
    URI.open(url)
  end

  t = Time.now
  h = http_client_wrapped(client)
  c = wasmer_current_download_count(h)

  {time: t, count: c}
end

def http_client_wrapped(http_client)
  http_client.call('https://github.com/fluxcd/flagger/pkgs/container/flagger')
end

def http_client_read
  http_client_wrapped.read
end

puts get_current_stat_with_time
