require 'gammo'
require 'open-uri'
require 'wasmer'

BIG_HONKIN_SELECTOR = "#repo-content-turbo-frame > div > div > div > div.d-flex.flex-column.flex-md-row.mt-n1.mt-2.gutter-condensed.gutter-lg.flex-column > div.col-12.col-md-3.flex-shrink-0 > div:nth-child(3) > div.container-lg.my-3.d-flex.clearfix > div.lh-condensed.d-flex.flex-column.flex-items-baseline.pr-1".freeze

def wasmer_current_download_count(html)
  file = File.expand_path "stat.wasm", File.dirname(__FILE__)
  wasm_bytes = IO.read(file, mode: "rb")
  store = Wasmer::Store.new
  module_ = Wasmer::Module.new store, wasm_bytes
  wasi_version = Wasmer::Wasi::get_version module_, true
  wasi_env =
    Wasmer::Wasi::StateBuilder.new('wasi_test_program')
      .argument('--test')
      .environment('COLOR', 'true')
      .environment('APP_SHOULD_LOG', 'false')
      .map_directory('html', './cache')
      .finalize
  import_object = wasi_env.generate_import_object store, wasi_version

  instance = Wasmer::Instance.new module_, import_object
  instance.exports._start.()

  return "42"
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

def get_current_stat_with_time(http_client)
  t = Time.now
  h = http_client.call('https://github.com/fluxcd/flagger/pkgs/container/flagger')
  c = wasmer_current_download_count(h)

  {time: t, count: c}
end

client = Proc.new do |url|
  URI.open(url)
end

puts get_current_stat_with_time(client)
