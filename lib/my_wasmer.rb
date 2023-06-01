require 'wasmer'
# require 'pry'

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
      raise ScriptError, "#{stdout.read}, #{stderr.read}, #{$!.message}"
    end
  ensure
    $stdout.reopen old_stdout
    $stderr.reopen old_stderr
  end
end

def wasmer_current_download_count(html, repo, image)
  # Save the html to a file: cache/content
  content_dir = 'cache'
  target_dir = File.join(content_dir, repo, image)
  cache_dir = File.expand_path target_dir, File.dirname(__FILE__)
  # binding.pry
  FileUtils.mkdir_p target_dir

  cache_file = File.join(target_dir, 'content')
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
      .map_directory('html', target_dir)
      .finalize
  import_object = wasi_env.generate_import_object store, wasi_version

  # Call the Wasm (it may use the system interface for IO)
  instance = Wasmer::Instance.new module_, import_object
  # results = instance.exports.count_from_html.()

  ## It turns out that Source Controller has >i32.max downloads (!)
  # begin
    returned_string = capturing_output do
      instance.exports._start.()
    end.chomp
  # rescue ScriptError => e
  #   binding.pry
  #   raise e
  # end

  return returned_string
end
