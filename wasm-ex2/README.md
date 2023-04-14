(WIP)

# Example

Copied from [docs.wasmer.io][]

Here we are using Ruby code to execute a web assembly.

TODO: write up this entire example

executed by a Wasm runtime (here, we use wasmtime).

You can imagine this Wasm module being portable to anywhere that Wasm can run!

```
git clone https://github.com/wasmerio/wasmer-ruby.git
cd wasmer-ruby
ruby examples/exports_memory.rb
```

There are no ruby gems, and bundler isn't used. This is fine but it's fair to
say that very few Ruby apps in the wild will be built exactly like this one.

[docs.wasmer.io]: https://docs.wasmer.io/integrations/ruby#start-a-ruby-project
