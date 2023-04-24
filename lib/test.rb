require 'gammo'
require 'open-uri'
require 'wasmer'
require 'pry'

BIG_HONKIN_SELECTOR = "#repo-content-turbo-frame > div > div > div > div.d-flex.flex-column.flex-md-row.mt-n1.mt-2.gutter-condensed.gutter-lg.flex-column > div.col-12.col-md-3.flex-shrink-0 > div:nth-child(3) > div.container-lg.my-3.d-flex.clearfix > div.lh-condensed.d-flex.flex-column.flex-items-baseline.pr-1".freeze

def wasmer_current_download_count(html)
  # Save the html to a file: cache/content
  content_dir = 'cache'
  cache = File.expand_path content_dir, File.dirname(__FILE__)
  cache_file = File.join(cache, 'content')
  IO.write(cache_file, html)

  # Load our web assembly "stat" from the stat/ rust package
  file = File.expand_path "stat.wasm", File.dirname(__FILE__)
  wasm_bytes = IO.read(file, mode: "rb")

  # Wasmer setup stuff
  store = Wasmer::Store.new
  module_ = Wasmer::Module.new store, wasm_bytes
  wasi_version = Wasmer::Wasi::get_version module_, true

  binding.pry

  # Setup the wasm module with some system parameters
  wasi_env =
    Wasmer::Wasi::StateBuilder.new('wasi_test_program')
      .argument('--path')
      .argument('html')
      .argument('--file')
      .argument('content')
      .environment('COLOR', 'true')
      .environment('APP_SHOULD_LOG', 'false')
      .map_directory('html', cache)
      .finalize
  import_object = wasi_env.generate_import_object store, wasi_version

  # Call the Wasm (it may use the system interface for IO)
  instance = Wasmer::Instance.new module_, import_object
  instance.exports._start.()

  # We haven't figured out how to capture that system IO,
  # maybe we should have just called it as a function
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
