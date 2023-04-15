require 'wasmer'
require 'pry'

# prelude.rb
class AssertionError < RuntimeError
end

def assert &block
  raise AssertionError unless yield
end
# /prelude

# Borrowed from: https://github.com/wasmerio/wasmer-ruby/issues/68
def capturing_output
  old_stdout = $stdout.dup
  old_stderr = $stderr.dup

  Tempfile.create '' do |stdout|
    $stdout.reopen stdout.path, 'w+'

    Tempfile.create '' do |stderr|
      $stderr.reopen stderr.path, 'w+'

      yield

      stdout.read
    rescue RuntimeError
      raise ScriptError.new stdout.read, stderr.read, $!.message
    end
  ensure
    $stdout.reopen old_stdout
    $stderr.reopen old_stderr
  end
end

def wasmer_current_download_count(html)
  # Save the html to a file: cache/content
  content_dir = 'cache'
  cache = File.expand_path content_dir, File.dirname(__FILE__)
  cache_file = File.join(cache, 'content')
  IO.write(cache_file, html.read)

  # Load our web assembly "stat" from the stat/ rust package
  file = File.expand_path "stat.wasm", File.dirname(__FILE__)
  wasm_bytes = IO.read(file, mode: "rb")

  # Wasmer setup stuff
  store = Wasmer::Store.new
  module_ = Wasmer::Module.new store, wasm_bytes
  wasi_version = Wasmer::Wasi::get_version module_, true

  wasi_env =
    Wasmer::Wasi::StateBuilder.new('stats')
      .argument('html/content')
      .map_directory('html', cache)
      .finalize
  import_object = wasi_env.generate_import_object store, wasi_version

  # Call the Wasm (it may use the system interface for IO)
  instance = Wasmer::Instance.new module_, import_object
  # results = instance.exports.count_from_html.()
  returned_string = capturing_output do
    instance.exports._start.()
  end.chomp

  return returned_string
end
