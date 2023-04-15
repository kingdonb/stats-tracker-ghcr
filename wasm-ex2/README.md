# Prelude for Example 2

The goal of this example is using Ruby code to execute a web assembly.

But there are some things from Example 1 we should review first! Let's have a
little diversion first, before diving in to our [second Wasm example][].

## Run Ruby in Wasmer

In the previous example, we used `wasmtime` – this time we'll choose `wasmer`!
Note that [both][wasmtime] of [these][wasmer] runtimes have a Ruby gem to run
Wasm modules. We're not switching out the runtime for any operational reason.
We should note though, [wasmer claims][] to have 1000x better startup speed,
and 2x better execution time! Grand claims like that sound worthy of testing.

If we can print "Hello" in less than 450ms, then we will have an improvement
over Ruby in wasmtime from the [previous example][] 😅😬

```
$ time wasmer ../wasm-ex1/my-ruby-app.wasm -- /src/my_app.rb
Hello

real	0m12.645s
user	0m51.935s
sys	0m1.032s
```

Haha, uh. Wait a second... wasn't this supposed to be faster?

```
$ time wasmer ../wasm-ex1/my-ruby-app.wasm -- /src/my_app.rb
Hello

real	0m0.213s
user	0m0.149s
sys	0m0.061s
```

It is faster! ... eventually. This is a 2.17x speed boost over `wasmtime`, but
why the **large** discrepancy between the first and second run?

### Why so slow?

The answer is in `~/.wasm/cache/` – that long delay was a compiler!  We can run
the compiler ourselves to front-load that extra waiting now that we know, but
there will inevitably be some trade-offs to consider.

```
$ time wasmer compile my-ruby-app.wasm -o my-ruby-app.wasmu
Compiler: cranelift
Target: aarch64-apple-darwin
✔ File compiled successfully to `my-ruby-app.wasmu`.

real	0m12.759s
user	0m50.678s
sys	0m1.097s

$ time wasmer compile ruby.wasm -o ruby.wasmu
Compiler: cranelift
Target: aarch64-apple-darwin
✔ File compiled successfully to `ruby.wasmu`.

real	0m12.707s
user	0m50.951s
sys	0m1.156s
```

First we compile the Wasm module with the embedded Ruby application, and time
it. No surprises here. There's basically no difference in compile time between
the two modules, which should be expected (since we know that Ruby libraries
are not compiled at all, they simply get embedded in the assembly as a vfs.)

The user time indicates this compiler is multi-threaded, so the more processor
threads we can throw at the compiler, the faster it will go. That's handy, and
it may turn out to be useful information later!

### How is the size?

Now we do expect to see a difference between those two assemblies at runtime,
due to their size. But there's something else noteworthy at this point:

```
$ du -sh *.wasm
 38M	my-ruby-app.wasm
 16M	ruby.wasm

$ du -sh *.wasmu
 89M	my-ruby-app.wasmu
 67M	ruby.wasmu
```

The original assembly (app+ruby) has grown by 2.34x in size, and Ruby itself
(the stripped interpreter without any supporting libraries) has grown to 4.18x
larger than before! The uncompiled Ruby files haven't grown, so the larger
number tells us how much compilation affects the Wasm code's representation.

If we were worried about serving these modules to Web clients before, who will
be waiting while the module is downloaded to their local machine, well... we're
definitely sweating now. Depending on the size of our codebase, it begins to
beg the question of whether it will be more expensive in terms of start time
for the user to download the compiled web assembly or compile it locally.

### Runtime Performance

Both options look bleak, but we're not only here for client-side execution! Web
assembly is not just for web, it's **portable**. (Reassuringly, he says...)

After the previous example, we already knew there will be problems for web the
larger a web assembly gets; if clients need to cold-start, or can't be asked to
pre-load and cache the modules locally, they're going to have to download a big
file and/or spend a whole number of seconds executing a compiler. This is slow.

It's worth asking what we hoped to gain by running Ruby in the web browser, if
performance is our leading KPI. "It's unlikely" for Wasm to bring a performance
boost against native JavaScript. Maybe that's true, and maybe it isn't. For us,
since Ruby is an interpreted language, we can consider some runtime performance
likely won't matter, it isn't the first KPI. What about the MVP time to market?

### Re-focus on goals

Ruby is easy and fun to write. Ruby claims to optimize for developer happiness.
And Rails (perhaps the most popular server-side framework for Ruby) already has
many powerful tools for optimizing client-server as well as creature comforts
to make building rich experiences with minimal JavaScript quite convenient.

Look at [Turbo][], [Stimulus][], and [Hotwire][] for examples of this.

The first Ruby release to support WASI and Wasm as a compilation target was
[version 3.2.0-preview1][] and the release notes remind us of the goals of
porting Ruby to Web Assembly. Despite what you may have heard before, runtime
performance [is now][] and also [has long been][] a primary goal of Ruby!
But let's read the statement in the release notes:

> running programs efficiently with security on various environment

Yes, we are building portable software that can run in any environment, even
in a web browser. That's an environment where security must be a top concern.
The same can be said for servers, or any context that handles client input.

### Business Logic

Ruby is a full-featured programming language, not simply a scaffold for our
app. Web Assembly is designed without many capabilities that are typically
available to the programmer in Ruby. From the [Web Assembly spec][]:

> WebAssembly provides no ambient access to the computing environment in which
> code is executed. Any interaction with the environment, such as I/O, access
> to resources, or operating system calls, can only be performed by invoking
> functions provided by the embedder and imported into a WebAssembly module.

Since our browser won't allow I/O, access to the file system, etc. we can't
depend on those capabilities. Maybe other runtimes will grant them, but we
must work within the framework of what we are granted and what we have chosen.

### Tree Shakers

Similarly there isn't any framework in Ruby to say "Hey, I only intend to call
`puts` and pass a simple string to it, so don't include any of that other
nonsense because I don't want that." Maybe one day we'll see a tree shaker that
optimizes these binaries for distribution!

The stated goals of Wasm in Ruby are efficiency and security. We can only run
Ruby in a web browser safely, thanks to the sandboxing model of Wasm. This is
reinforced by [The Bytecode Alliance][why-is-this-important-now] that says:

> running untrusted code in many new places, [...] opens up many security
> concerns, and also portability challenges

Think of the places that we are typically running Ruby now, before Wasm. The
web browser is not a typical target for Ruby code, even if Web Assembly can
enable this; it is questionable if we really need this code to run client-side.

In my experience at least, the Ruby code is most often hosted on a server.

### Marketing Web Assembly

Say it with me: "Web Assembly" is a marketing name. Just because we're building
Wasm targets does not mean we're targeting the web. What does "portable" mean,
and how much of our business logic should be portable before it begins to help?

And if we're permitting users to submit Ruby code and running it (in a browser
or in the server) then security again becomes a primary concern for us; we must
not permit the user to escape from our sandbox! We should isolate them from any
sensitive resources.

Nevertheless, we promised to show the Web assembly running in a browser, so now
that's what we'll do, (and a few other things to further our goals as well.)

# Example 2

Copied from [docs.wasmer.io][]

This time we're gonna run Ruby in the browser, with Wasm... and we will also
run our Wasm from within Ruby. The point is to show the portability of Wasm,
and how can this be useful.

There are no ruby gems, and bundler isn't used. This is fine but it's fair to
say that very few Ruby apps in the wild will be built exactly like this one.

[second Wasm example]: #example-2
[wasmtime]: https://bytecodealliance.org/articles/using-wasmtime-from-ruby
[wasmer]: https://github.com/wasmerio/wasmer-ruby#example
[wasmer claims]: https://wasmer.io/wasmer-vs-wasmtime
[previous example]: ../wasm-ex1
[version 3.2.0-preview1]: https://www.ruby-lang.org/en/news/2022/04/03/ruby-3-2-0-preview1-released/
[why-is-this-important-now]: https://bytecodealliance.org/#why-is-this-important-now
[is now]: https://goldenowl.asia/blog/ruby-3x3-is-it-actually-three-times-faster
[has long been]: https://blog.heroku.com/ruby-3-by-3
[Web Assembly spec]: https://webassembly.github.io/spec/core/intro/introduction.html#security-considerations
[Turbo]: https://turbo.hotwired.dev/
[Stimulus]: https://stimulus.hotwired.dev/
[Hotwire]: https://hotwired.dev/
