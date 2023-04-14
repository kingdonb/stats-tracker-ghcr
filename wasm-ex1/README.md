# Example 1

Copied from [github.com/ruby/ruby.wasm][]

This example shows that Ruby code can be packed into a web assembly module and
executed by a Wasm runtime (`wasmtime` from [The Bytecode Alliance][] is used).

You can imagine this Wasm module being portable to anywhere that Wasm can run!
Whether that is true, we can test in a separate example. Let's see Wasm running
Ruby in the terminal first, to explore the limitations and try out some things.

## Run Ruby in Wasmtime

```
# Download a prebuilt Ruby release
$ curl -LO https://github.com/ruby/ruby.wasm/releases/latest/download/ruby-3_2-wasm32-unknown-wasi-full.tar.gz
$ tar xfz ruby-3_2-wasm32-unknown-wasi-full.tar.gz

# Extract ruby binary not to pack itself
$ mv 3_2-wasm32-unknown-wasi-full/usr/local/bin/ruby ruby.wasm

# Put your app code
$ mkdir src
$ echo "puts 'Hello'" > src/my_app.rb

# Pack the whole directory under /usr and your app dir
$ wasi-vfs pack ruby.wasm --mapdir /src::./src --mapdir /usr::./3_2-wasm32-unknown-wasi-full/usr -o my-ruby-app.wasm

# Run the packed scripts
$ wasmtime my-ruby-app.wasm -- /src/my_app.rb
Hello
```

Above, the Ruby interpreter (`ruby.wasm`) and supporting libraries (`/usr`) get
packed together with our app source code into `my-ruby-app.wasm`, then the Wasm
runtime executes the ruby app in what we might call a "platform-agnostic" way.

The Ruby interpreter is a web assembly module, we pack it up into a virtual fs,
and all of our Ruby code is platform-agnostic as it's an interpreted language.
The `wasi-vfs pack` output is, another web assembly that includes `ruby.wasm`.

Great! It works!

### Limitations

But there are some serious plot holes in this story; I'll point out a few:

The host OS does not know about `.wasm` modules; we'll need a Wasm runtime to
make them executable on our platform.

Printing output to the terminal does not feel very "web." (More on that later.)

#### Performance

The compiled module carrying around the whole Ruby interpreter and its entire
context certainly seems likely to blow up the performance budget, see how big:

```
$ du -sh ruby.wasm 3_2-wasm32-unknown-wasi-full/usr/ my-ruby-app.wasm
 16M	ruby.wasm
 27M	3_2-wasm32-unknown-wasi-full/usr/
 38M	my-ruby-app.wasm
```

The `ruby.wasm` is a full Ruby interpreter, but that's not useful by itself.
We will likely need the Ruby standard library and bundled gems to do anything.
The module must be self-contained.

We used `wasi-vfs` to put our Ruby code in the virtual filesystem context where
`ruby.wasm` runs.

Shipping the artifacts together as a single assembly to web clients is frankly
a complete non-starter, unless they can download it once to re-use many times.

And if we wanted the client to run many Ruby wasm modules, we are definitely in
trouble. They'll need to download a full interpreter and standard lib every
time, multiplied by each assembly that runs.

That's not all...

```
time wasmtime my-ruby-app.wasm -- /src/my_app.rb
Hello

real	0m0.462s
user	0m0.387s
sys	0m0.063s
```

One of the [often cited advantages][] of running Wasm is the insanely fast
cold-start time. Have we been misled? No, not at all, but [Ruby's gonna Ruby][].

Let's try removing all of the bundled gems and the standard libraries, for fun.
Fortunately, it turns out that `puts` from our example is a Kernel function, so
this time we really didn't need the extra 27MB of support libraries!

```
$ echo "puts 'Hello'" | time wasmtime ruby.wasm
`RubyGems' were not loaded.
`error_highlight' was not loaded.
`did_you_mean' was not loaded.
`syntax_suggest' was not loaded.
Hello
        0.22 real         0.18 user         0.02 sys
```

We can see this result is 2.1x faster, and the binary `ruby.wasm` is 2.3x
smaller than our pack. This strong correlation suggests most of the used time
is spent reading the assembly into memory!

(Please retry this experiment with a RAM-backed filesystem if you have access
to one, and let me know how it turns out. I'm on MacOS today, so this is left
as an exercise for the reader.)

### Hypothesis

If we can pre-load the heavy parts, that's likely to make a big difference.

If this seems like a lot for just `Hello`, suspend your disbelief and trust
that optimizations will come. We can't ignore these issues forever, but it's
premature to start optimizing before we've added some additional complexity.

### Additional Limitations

There are no ruby gems, and bundler isn't used. This is fine but it's fair to
say that very few Ruby apps in the wild will be built exactly like this one.

When we say "web assembly" there's a high probability that readers would expect
to see an example running in a web browser. We haven't done that yet.

In the [next example][], we'll see if `my-ruby-app.wasm` (a 35MB file) can
actually print `Hello` from within the browser, and how poorly it performs.
On the other hand, we should be able to separate the Wasm module from the app
so the Ruby interpreter can be cached. (I won't do that, but we can find it
[here][in case you have doubts] – just to get out of the way, it's possible!)

It should be clear that downloading 35MB to print Hello World is a wasteful
excess. But if you follow [The Bytecode Alliance][], you should understand
that portability to the web browser is just a part of Wasm, and performance
wasn't the only goal. This is just the first example!

[Keep reading][next example], or [return to the top](https://github.com/kingdonb/stats-tracker-ghcr/)

[github.com/ruby/ruby.wasm]: https://github.com/ruby/ruby.wasm#quick-example-how-to-package-your-ruby-application-as-a-wasi-application
[The Bytecode Alliance]: https://bytecodealliance.org/#faq
[often cited advantages]: https://www.google.com/search?q=wasm+fast+cold+start
[Ruby's gonna ruby]: https://www.fermyon.com/wasm-languages/ruby#:~:text=below%20illustrates%20usage.-,Pros%20and%20Cons,-Things%20we%20like
[next example]: ../wasm-ex2
[in case you have doubts]: https://semaphoreci.com/blog/ruby-webassembly
