require 'gammo'
require 'open-uri'
require 'wasmer'

BIG_HONKIN_SELECTOR = "#repo-content-turbo-frame > div > div > div > div.d-flex.flex-column.flex-md-row.mt-n1.mt-2.gutter-condensed.gutter-lg.flex-column > div.col-12.col-md-3.flex-shrink-0 > div:nth-child(3) > div.container-lg.my-3.d-flex.clearfix > div.lh-condensed.d-flex.flex-column.flex-items-baseline.pr-1".freeze

def wasmer_current_download_count(html)
  # Save the html to a file: cache/content
  content_dir = 'cache'
  cache = File.expand_path content_dir, File.dirname(__FILE__)
  cache_file = File.join(cache, 'content')
  IO.write(cache_file, html.read)

  # Load our web assembly "stat" from the stat/ rust package
  file = File.expand_path "stat.wasm", File.dirname(__FILE__)
  # wasm_bytes = IO.read(file, mode: "rb")
  wasm_bytes = Wasmer::wat2wasm(
    (<<~WAST)
    (module
      (type $sum_t (func (result i32)))
      (func $sum_f (type $sum_t) (result i32)
        i32.const 1
        i32.const 2
        i32.add)
      (export "count_from_html" (func $sum_f)))
    WAST
  )

  # Wasmer setup stuff
  store = Wasmer::Store.new
  module_ = Wasmer::Module.new store, wasm_bytes
  # wasi_version = Wasmer::Wasi::get_version module_, true

  # Setup the wasm module with some system parameters
  # wasi_env =
  #   Wasmer::Wasi::StateBuilder.new('stats')
  #     .argument('html/content')
  #     .map_directory('html', cache)
  #     .finalize
  # import_object = wasi_env.generate_import_object store, wasi_version

  # Call the Wasm (it may use the system interface for IO)
  instance = Wasmer::Instance.new module_, nil
  # Let's not call main...
  # instance.exports._start.()
  # results = instance.exports.count_from_html.()
  results = instance.exports.count_from_html.()

  return results
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
