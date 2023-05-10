# Prelude for Example 2

The goal of this example is using Ruby code to execute a web assembly.

But there are some things from Example 1 we should review! Let's have a little
diversion first, before diving in to our [second Wasm example][].

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
run our Wasm from within Ruby, on a server. The point is to show portability of
Wasm, and let's reserve our judgment how this can or might be useful til after
we've seen it actually working.

We're not going to use Wagi, not going to give up threading, native extensions,
we actually have some useful work we need to do in Ruby, and we're not sure yet
if Wasi will be up to every task. But we don't need our Wasm to do every job.

The Wasm will have one job; that's what modular design and microservices were
supposed to do for us. It's not just Web Assembly, they're Web Assemblies!

We create software with one job, so we can vet and test it extensively. The job
should not be expanding to cover any incidental complexity that may come up. A
Wasm has a spec; the job runs to completion, then it goes away. This is new and
useful. We're ultimately going to use this implementation to "go serverless."

This Wasm's job was to print "Hello." Another one might parse some HTML that it
receives as a string parameter... or maybe something less contrived?

I'm not here to tell us what to use it for, I'm just here to show how it can be
used, and try my best to avoid overcomplicating things too damn much.

### We're Ruby Programmers

The Ruby software may do many jobs, and it could be a success if we turn even
10-20% of those tasks into Wasm modules. Let's not assume we need the entire
stack to be so portable. Code will be running on a singular target eventually.
That target can be a Ruby host with native C extensions hosted alongside Wasm!

Then we'll probably get the best and worst of both worlds.

I think as Ruby programmers, we know how to serve up static assets. It turns
out that Spin solves this problem for us as well; we can do Wagi and Wasi, it
saves us from TLS termination, keeps us from thinking about threading. But we
know that threads exist, and we need to get a job done. We may need threads.

I think that Wasm is trying to trick us into using a compiler, and I think we
should not bite yet. Let us keep our Web assembly minimal, and not attempt to
build the entire stack as a single Web assembly, or as a full suite new-stack
with unlimited potential for surprising things to get in the way of reaching
our goal, a working MVP app with all the features that we scoped, documented.

### Kubernetes and Helm

It may be that Spin adequately hosts our app, and we don't need any Rails!
Or perhaps, Hotwire is the greatest thing since sliced bread, and the native
extensions baked into Rails' upstream dependencies will win over the day.

Our job as a platform team is to save time here by making an agnostic choice.
We know that we [can host Spin][] apps on Kubernetes, but we should know as
well that it doesn't matter what we host, as an abstraction doesn't care what
content it abstracts over, we [can host any app][] with Helm and the Helmet
library chart, it may be a traditional Rails app for example, and you may not
even [need to write][] a chart, a Dockerfile, any of that to get your app off
the ground thanks to buildpacks, which we can leverage with [Hephy Workflow][]
if you're squeamish about Kubernetes at all, we can yet pretend it's Heroku.

The decision today, since we already have a modern Rails 7 app with esbuild
support in a post-webpacker world, is to just use Rails.

When we have more than one Web Assembly module of our own, perhaps it makes
more sense to invert the stack and go full Wasm, hosting everything in Spin,
but as long as there's only one Wasm, I think it makes more sense to simply
run a Rails server the traditional way, and call the Wasm when we need it.

This way we can use any familiar Ruby tooling along the way, without regard
for whether it depends on any C extension or not. So it's decided, we'll do
Rails and we'll host it on Kubernetes, with Helm.

### Ruby-in-Ruby with Wasmer

As an experiment, I tried to run the Ruby wasm via the wasmer gem, from my
Ruby host VM, a ruby-in-ruby. I'm not sure why anyone would want to do this
but I couldn't get that to work. So I had to take a step back and think.

There's a broader point to be made about compilers and optimizing paths here:

Errno rube goldberg; if I'm going to compile something into a Web assembly as
a Rubyist running C-ruby, it is not going to be Ruby. At this point I felt as
though I became enlightened, as there was clearly nothing to be gained by
running Ruby as a Wasm from within C-Ruby itself.

The Wasm would be from some different language, most likely a compiled one, or
the host language would be a non-Ruby VM. If I wanted to call a Ruby function
from within Ruby, I'd just call it directly, as monoliths have done since time
immemorial.

#### Wasmer Ruby Examples

Look at [Ruby examples][] in the Wasmer docs to see what I mean:

* How to instantiate a module from Wat to Wasm
* How to use JIT engine to compile

(which, by the way, are the same thing);

* How to use Cranelift compiler, again the same thing!

Now that you're using a compiler, however you want to call it,
we move onto what you can do with compiled code;

* Exporting a function from the Web Assembly,
* Export some memory,
* Export global memory
* Importing functions,
* Exiting early from an imported function

(also known as "raising an exception")

And then the big one, "how to run a compiled Wasi module" which has the whole
interface you'd expect from a stand-alone program; environment varibles, args,
perhaps a directory mapped from the host filesystem?

Aren't those the things we wanted to do, as systems programmers? (What's that?
We're Ruby programmers? Oh...)

I'm beginning to see and grok why this isn't catching on very fast! Maybe we
can still get it to help us.

### Let's pick another language

Since the Ruby interpreter is a Wasi program, and Wasi seems to be the most
difficult example, I think we'd better find a simpler way to build our Web
Assembly that we want to run in Ruby.

Maybe we'll write it in Rust. Then we'll be using Wasm the way it is intended
– as a compiler-bridge between two languages, not as an extra complicated way
to run more code from the same language we already had.

It doesn't matter yet. We said we were going to do it in a browser though. We
can still run "Hello World" in the browser and do a useful work in a Wasm on
the host server instead. Putting Ruby in Wasm to run on Ruby is an anti-pattern
now. We can already just run Ruby functions where we need to in Ruby, don't
need to import them from anywhere; just use `require` like normal Rubyists!

If we want to print Hello World in Web Assembly, from an exported function, we
can certainly do it without another Ruby. There's no need to invoke it twice.
We're not making an apple pie from scratch, no need to invent the universe.

Hello World in Wat is here:

```
(module
    ;; Imports from JavaScript namespace
    (import  "console"  "log" (func  $log (param  i32  i32))) ;; Import log function
    (import  "js"  "mem" (memory  1)) ;; Import 1 page of memory (54kb)
    
    ;; Data section of our module
    (data (i32.const 0) "Hello World from WebAssembly!")
    
    ;; Function declaration: Exported as helloWorld(), no arguments
    (func (export  "helloWorld")
        i32.const 0  ;; pass offset 0 to log
        i32.const 29  ;; pass length 29 to log (strlen of sample text)
        call  $log
        )
)
```

So in the browser, we'll use `my-ruby-app.wasm` from the first example. It's
going to have Ruby in the browser. It's going to run as a standalone program,
and we'll see how bad that looks. It isn't going to win any overall performance
contests. It isn't winning usability contests, unless the goal is unit testing.

We don't know how to make use of any high-order functions other than what we've
been provided in the Wasi (an environment, stdio for logs, and maybe some files
that we got shipped together with the interpreter in our Wasm module file.)

But in our Ruby-C VM, where we required the `wasmer` gem to provide the support
for running Wasm code and interfacing with Wasi, we can do something else. Run
compiled code as part of a Ruby script. It can pass us functions, and we call
them, or vice versa. This is the real intended use of Wasm, as I perceive it.

If we can substitute one compiled program for another, and every behavior we
intended for the first compiled program is equally satisfied by the secondary
program, then we've learned a new duck-typing, or jet-propulsion if you like!

Source: [opensource.com][]

We're going to follow the Hello World according to Wasmer's examples. It has
at least three of the features they mentioned in the outline: import function,
importing memory, calling the function, and instantiating itself as a module!
If we can do all these things, then we can definitely use Wasm in our Ruby.
But the future of Ruby as an interpreted language in the Wasm execution space,
will still remain unclear for some time ahead.

## Run Wasm in Browser

First we said we'd try my-ruby-app.wasm in the browser. This is going to be a
very short experiment, and it's just going to prove extremely quickly it's a
bad idea to ship Wasi+vfs with Ruby, that shouldn't be pursued any further.

That's probably too strong for how quickly we gave up, and how many things we
haven't tried yet, but we have work to do; (if you disagree, you can give your
own talk to prove how much possibility was left on the table. I'll watch it!)

Obvious low-hanging fruits that could make this experience better: mruby or
another smaller Ruby interpreter; running code coverage tools and tree shaking
out all the Ruby code we didn't intend on visiting in any function we exposed.
Caching and/or streaming the code modules we need and loading them only when
we need them. Those are all great ideas I didn't have time to try on my own.

## Run Wasm in Ruby

Second we said we'd try to do something actually useful with Wasm in Ruby
instead of just "Hello World" in a second Ruby interpreter. I settled on HTML
parsing, as a Wasi program. The use of Wasi helps us vault over the fact of
Wasm lacking any sort of String type.

There's a simple HTML parsing task that landed on my doorstep through the
DX team at Weaveworks: we need to know how many downloads a package got, and
GitHub only exposes this number in one public place: on the `pkgs/container`
endpoint that is found under each repository, for each package hosted there.

We can pass fetched HTML content into the Wasi program as a simple file in a
directory context, which the Wasm program can then read for itself. There is no
imported or exported function. Only STD/IO, and this simplifies quite a bit.

That also makes it very easy when we are to receive a string back from Wasi,
whether it contains a number or a whole typed struct deserialized into text.
We can do sanity checks on the output from Ruby; if we don't see a number in
the returned output that looks in the expected range, flag it as an error.

We've stuck to Hello World examples here, but while we've been here, a separate
thread has been developing in the `../lib/` folder. Our function that does the
useful work (an HTML parser) has been developed as a Wasi, and next time we'll
keep developing it until we can either count it as part of a whole solution, or
end by relegating these bits to the bucket until somebody finds a use for them.

### Limitations

TODO

There has been no consideration of types. In Ruby, it has been possible to use
typed data for some time. Whether those types are helpful to interact with Wasm
in any context, is a question I have not explored before.

#### Performance

TODO

It's been conjectured that shipping around almost 40MB in extra weight is going
to cancel out any performance benefit from using Wasm. But that's assuming we
didn't already use Ruby: we can discount the complexity we were already paying
for. We don't need to pay for it twice.

I honestly have no idea why `ruby.wasm` packed together in a wasi-vfs failed to
run under Wasmer-ruby. Maybe updating the environment to include our own dirmap
caused the Wasi VFS to forget its already existing dirmap.

It was a silly idea anyway, but perhaps now that we know a bit more about the
Wasi and how it fits in the bigger picture of [Wasm, WASI, Wagi][], we can yet
try it again. It seems likely that could have been made to work.

Now we've learned to minimize Wasm bytes through better living and compilers.
We need not measure the performance of Ruby in the Wasm before we have a valid
use case for that. As long as Hello World is the job we've scoped for our Wasm,
we can report our timed benchmarks from the lightest three implementations:

1. A native ruby `puts "Hello World"` in isolation, (running VM preloaded)
2. A Wat "Hello World in Wat" hand-optimized by a Wasmer (the human kind)
3. "Hello World" as Rust program, compiled (compare with our HTML parser)

Can Wasm print Hello World faster than the Ruby VM itself? And can a compiled
binary print Hello World faster than one written as a minimal implementation by
a human that understands how to write Wasm? I hope the answer to both is "No."

### Testing Hypothesis

In the previous example, we talked about "pre-loading the heavy parts" as a
hypothesis. We suggested that a big download would be easier to stomach, if we
just ensure that users only need to download once, and they could go and make a
cup of coffee while they wait.

This naive approach can take us so far, but in the real-world scenarios your
users are in a funnel, and every second counts. Performance matters. That's why
we decided to explore compiled runtime (Wasm) with goals not only for improving
our portability, but also performance.

In this example we explored a new way to positively impact the performance
metric: doing less unnecessary work! We can see that Hello World executes much
faster when the binary is smaller, and the binary can be smaller because there 
is no interpreter between the runtime and our running intent expressed as Wasm.

TODO: Tie these ideas together with a hypothesis to test.

The hypothesis to test: can you print Hello World even faster with a compiler?
Can you parse HTML even faster?

The answer for both might be different answers. Let's find out if either Hello
World or HTML parsing is faster in a compiled language than in pure Ruby.

#### Additional Comparison

We can compare as well: native C extensions vs. pure ruby, Rust, and Wasm.
Note that we haven't provided a native C extensions version of "Hello World",
or supposed the existence of a minimal HTML parser with CSS selectors support.

(If you know of an HTML parser that has been written in pure Wat...)

So: Hello World is measured only as Ruby, Rust, and pure Wat implementations.
Also: HTML parse is measured only as native C, Ruby, and Rust compiled to Wasi.

That was too many words, our benchmarking test matrix looks like this:

```
              Native C   Ruby   Rust   Wat2wasm
            +----------+------+------+----------+
Hello World |          |  XX  |  XX  |    XX    |
            +----------|------|------|----------+
HTML Parser |    XX    |  XX  |  XX  |          +
            +----------+------+------+----------+
```

We're expecting to see better performance from compiled languages in general,
but we can't be sure that the speed boost of compilation offsets the penalty
we pay for "going outside of the box." A speed boost shouldn't imply we need
to abandon using our Ruby system as host platform in order to capitalize on it.

We mean by this: as we use Ruby as a measurement tool, the cost of starting a
Ruby VM gets discounted from the total, and we take it for granted. But we do
measure the startup cost of a Wasm VM; as Wasmer claims a 1000x startup speed,
I think compiled has a shot to beat us, even though Ruby gets a "head start."

### Further Exploration

In the [next example][] we're going to build the function that we need in the
top-level program, an HTML parser that accepts a memory or a client function
with the HTML in it, and returns a number that was parsed from the HTML using
CSS selectors.

Since we know that most of our time is spent creating the universe, and very
little time is spent actually printing Hello World, we can expect to see gains
by removing the Ruby interpreter (the whole universe) and it's likely that our
Rust program that shares memory into Ruby can actually perform the parsing
faster than our old Ruby wasm could, or even the C extensions version could.

This is going to be my first Rust program, I hope you're all happy. I expect to
see one final benchmark where Rust's HTML parsing library blows both Nokogiri
and Gammo performance out of the water, and if we're lucky, we may even see an
appearance from the wildcard, a Gammo running in Pure Ruby, compiled for Wasm!

⚾️🔥

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
[docs.wasmer.io]: https://docs.wasmer.io/integrations/ruby#start-a-ruby-project
[can host Spin]: https://github.com/kingdonb/taking-bartholo#inventory
[can host any app]: https://github.com/companyinfo/helm-charts/tree/main/charts/helmet#background
[need to write]: https://github.com/kingdonb/hephynator#readme
[Hephy Workflow]: https://blog.teamhephy.info/#install
[Ruby examples]: https://github.com/wasmerio/wasmer-ruby/tree/master/examples
[opensource.com]: https://opensource.com/article/21/3/hello-world-webassembly
[Wasm, WASI, Wagi]: https://www.fermyon.com/blog/wasm-wasi-wagi



[next example]: ../wasm-ex3
