To build the Wasm dependencies, you need Rust first:

```shell
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# (restart your terminal per the printed instructions from rustup)
$ rustup target add wasm32-wasi
```

For `wasm-strip`, you can get it from WABT:
(For that, you will also need Cmake and Ninja)

```shell
$ brew install cmake ninja

$ git clone https://github.com/WebAssembly/wabt
$ cd wabt
$ git submodule update --init
$ make gcc-release
# (or choose another build target for any compiler you have)
# sudo --preserve-env=PATH make install-gcc-release
```

Finally for optimized binaries, we'll use `wasm-opt`

```shell
# sudo apt-get -y install binaryen
```

If you have already Ruby 3.0.6 installed (if not, install from [RVM.io][])

```
\curl -sSL https://get.rvm.io | bash -s stable
```

You can do:

```shell
$ bundle install
# (From the Gemfile in the repository root, this installs the 'wasmer' gem)
```

Then run:
```shell
$ make
```

Now you should be able to run `make` and see the test passing.

[RVM.io]: https://get.rvm.io
