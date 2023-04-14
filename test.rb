require 'nokogiri'
require 'open-uri'

BIG_HONKIN_SELECTOR = "#repo-content-turbo-frame > div > div > div > div.d-flex.flex-column.flex-md-row.mt-n1.mt-2.gutter-condensed.gutter-lg.flex-column > div.col-12.col-md-3.flex-shrink-0 > div:nth-child(3) > div.container-lg.my-3.d-flex.clearfix > div.lh-condensed.d-flex.flex-column.flex-items-baseline.pr-1".freeze

def current_download_count(html)
  h = Nokogiri::HTML(html)

  t = h.css(BIG_HONKIN_SELECTOR)
  u = t[0].children
  v = u[3].attributes["title"].value
end

def get_current_stat_with_time(http_client)
  t = Time.now
  h = http_client.call('https://github.com/fluxcd/flagger/pkgs/container/flagger')
  c = current_download_count(h)

  {time: t, count: c}
end

client = Proc.new do |url|
  URI.open(url)
end

puts get_current_stat_with_time(client)
