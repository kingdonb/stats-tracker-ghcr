require 'gammo'
require 'open-uri'
require 'wasmer'

# prelude.rb
class AssertionError < RuntimeError
end

def assert &block
  raise AssertionError unless yield
end
# /prelude

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
    (type $hello_t (func (result i32)))
    (func $hello (type $hello_t) (result i32)
        i32.const 42)
    (memory $memory 1)
    (export "hello" (func $hello))
    (export "mem" (memory $memory))
    (data (i32.const 42) "Hello, World!"))
  WAST
)


  # Wasmer setup stuff
  store = Wasmer::Store.new
  module_ = Wasmer::Module.new store, wasm_bytes

  # Setup the wasm module with some system parameters
#   import_object = Wasmer::ImportObject.new
#   sum_host_function = Wasmer::Function.new(
#     store,
#     method(:html),
#   #                         x                  y                    result
#   Wasmer::FunctionType.new([Wasmer::Type::I32, Wasmer::Type::I32], [Wasmer::Type::I32])
# )

  # Call the Wasm (it may use the system interface for IO)
  instance = Wasmer::Instance.new module_, nil
  pointer = instance.exports.hello.()
  assert { pointer == 42 }

  memory = instance.exports.mem
  assert { memory.is_a?(Wasmer::Memory) }
  reader = memory.uint8_view pointer
  returned_string = reader.take(13).pack("C*").force_encoding('utf-8')
  assert { returned_string == 'Hello, World!' }

  # results = instance.exports.count_from_html.()

  return returned_string
end

def html
  http_client_read
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
