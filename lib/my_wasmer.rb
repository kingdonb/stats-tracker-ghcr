require 'wasmer'
# require 'pry'

# prelude.rb
class AssertionError < RuntimeError
end

def assert &block
  raise AssertionError unless yield
end
# /prelude

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

  size_in_bytes = html.length

  memory = instance.exports.mem
  assert { memory.is_a?(Wasmer::Memory) }
  # binding.pry
  reader = memory.uint8_view pointer
  # binding.pry
  returned_string = reader.take(13).pack("C*").force_encoding('utf-8')
  assert { returned_string == 'Hello, World!' }

  # results = instance.exports.count_from_html.()

  return returned_string
end
