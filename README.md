# Stats Tracker (GHCR)

The purpose of this project is dual: to track the number shown on a "Packages"
counter that GitHub provides in real-time, showing how many billion downloads
of Flux and Flagger there were on any given day, and maintaining a web UI that
shows the collected data over time in a useful way.

And, to provide a built-up series of examples that can help us try to use Wasm
(Web Assembly) more fruitfully and productively in our Ruby application build!

That's right, Web Assembly is being treated as an end here, not as a means.

## Why Web Assembly

Our goal is to use Web Assembly for something because we came here to see that.
We have a hypothesis that we're going to see long-term sweeping benefits coming
in the areas of: Security, Performance, Portability; and ultimately we believe
in making our own lives easier through adoption of Web Assembly.

Let's try and see if that hypothesis holds even a little bit of water, while we
do some useful work for a real user: the DX group wants to know how many users.

We do these things not because they are easy, but because we thought they would
be easy. Such is the way of the modern developer! Come with me, on a journey...

### Plan

Todo:

* [ ] Collect the data (it should go somewhere permanent)
* [ ] Update the data store with new data on some interval
* [ ] Build a way to represent the collected data visually
* [ ] Show failed collections on the visual representation too

Stretch:

* [ ] Alerting with Prometheus when collections are failing
* [ ] Deploy this on Kubernetes, with minimal web interface

Value-add extras:

* [ ] Allow scaling the deployment/web client process to zero
* [ ] Show how Prometheus can retain metrics while scaling to zero
* [ ] Try to split the front-end web service from the collector
* [ ] Review code re-use opportunities: did we find any of them?
* [ ] Add good documentation about how to run this in perpetuity

## Examples

* [Example 1][] - Run Ruby 'Hello World' in WebAssembly with `ruby.wasm`
* [Example 2][] - Run Wasmer in Ruby, run Wasm/Wasi in a Browser (finally!)
* [Example 3][] - Parsing HTML and HTTP client from Web Assembly with Spin

## Known Limitations of Wasm

There is one major leading known limitation of Wasm with respect to Ruby, and
experienced Rubyists are likely to balk at this one: it's not yet possible for
our Wasm Ruby to incorporate compiled C code, or "native extensions" as they
are commonly known in the Ruby world, with Gems and Bundler for dependencies.

This means that we can write Ruby, bundle and ship it with a Ruby interpreter,
and incorporate any Ruby gems that might be useful for advancing towards a goal
of the project... except when that gem we'd like to depend on has an outside
dependency on any external C library, or some other non-Ruby code.

For this reason, we've replaced the more common "Nokogiri" gem with a pure Ruby
"Gammo" - if we're not familiar with those words, don't worry, as I'll provide
these helpful definitions I found on the internet:

* Nokogiri: a Japanese pull saw [citation: dev.to, Jessie vB](https://dev.to/jvon1904/what-is-nokogiri-48m4)

* Gammo: one of the three aliens on the UFO in Jolly Roger's Lagoon. You have to activate all four generators with Ice Eggs in 20 seconds to power up the... [citation: Banjo Kazooie Wiki](https://banjokazooie.fandom.com/wiki/Gammo)

No, really: these are both HTML parsing libraries.

Nokogiri uses a C extension, and Gammo does not. Besides that one difference,
as a sometimes-user of CSS selectors in HTML parsing, I have so far found them
both to be nearly interchangeable. This may be naive, but I have simple needs!
And I have not done any performance measurements yet, but let's do that later.

I'm not going to stand here and tell us that C extensions are widely wrong or
that we should not use them in general, but I will suggest that "C extensions
are a source of pain" may be one of the assumptions naively embedded in one of
the leading answers to the question:

### **Why Wasm**

If you had to pick one of these technologies to bring with you onto the island,
C extensions or Wasm modules, which one would you pick? That's what I'm asking.

I think that in time, we will find a reliable way to embed native extensions in
the Wasm module alongside of that Ruby interpreter, which also is written in C.

But assuming we never do, and assuming again: we have to pick one, Wasm or C.

Which would we pick?

I would pick Wasm because I have never had anyone suggest I build a C extension
into a Ruby gem, personally, and I frankly don't even know yet how to do that
at all, let alone do it "safely."

Plus, you all showed up today. Would you all have come to a talk about writing
C extensions? Millions of us hominids at our typewriters... know what we like.

#### Safety

Wasm is said to be all about safety. Further, we don't really need to pick: we
can definitely expose C functions, or JavaScript functions, so they can all be
called in at least a handful of other ways via Wasm, like we can do from Ruby.
We just can't do it indiscriminately and without the awareness, like we could
with Ruby gems and the native extensions support they permitted via Bundler.

I must be honest now: I cannot sell us on Wasm, if we're not sure why we came.
I definitely don't get any cash bonus if you all decide to use Wasm today.

There's a degree of faith in my own assumption that spending time with this new
Wasm technology is going to lead to any improvement in outcomes for any of us,
directly or indirectly. If we can sprint to the finish line quickly enough, at
least, I think we can count that as a victory of a certain kind, anyway.

Let's show how Wasm can be used in some real problems!

#### Constraining Complexity

I'd like to posit here, for the record, that mixing code modules of different
types adds new complexity that may bubble out of the abstraction and ultimately
make our lives more difficult; so perhaps doing that is a thing to minimize.

You may have accepted C extensions already without thinking about it, so we may
consider that as some complexity we've got to live with. We won't actually see
it or encounter it, whereas the Wasm in our project, a new choice we're being
presented, may feel as though we can save a bundle by rejecting it right now!

I work on a project that used to depend on C extensions and we did remove them
all. Not this project, not in Ruby... can you guess which project I'm talking
about? I'll give you a hint: we did not have any "Wasm reason" for doing that.

The real project I'm talking about is Flux, not this toy project I'm building.
Flux is written in Go, not in Ruby, but that's not important right now. We'll
use Flux to deploy on Kubernetes... and it's also certainly fair to say we may
not have needed all that, just for this toy Wasm app. But for a lightning talk?

👩‍🍳💋🤌

Let's allow that perhaps some of this complexity is unavoidable, or at least it
can't always be avoided profitably: we cannot rewrite all HTML parsers in pure
Ruby, nor would it benefit us doing so.

"You Ain't Gonna Need It" (YAGNI) can only take us so far.

Point being, we only needed one C extension, and now we don't need it because
Wasm has now constrained our choices. Maybe we never needed it before either.

Are we now much better or much worse off for having made this change?

### Dependency Constraints

Depending on "..." we may or may not be able to live with such constraints.

It's easy to avoid C extensions parsing HTML in Ruby: just pick a different
library that doesn't use C extensions!

But careful: this is the same logical fallacy we must consistently be willing
to leap across, if we mean to become successful Wasm adopters.

Just knowing that we have added or removed a new type of module isn't telling
much if anything about the overall complexity of a whole solution, or even its
constituent parts.

It might not even matter if Wasm is more or less complex than C extensions.

It's much too early to tell which constraints will lead to long-term success.
To know how it turns out, we may have to blaze the trail and forge ahead some.

I definitely hope we're all wearing our hip-wader boots, it's gonna get deep!

## Thank You

Thanks for reading all this, now I hope you enjoy the examples, so we can make
use of this tool (whether you care about the Wasm story even a little or not.)

Everyone must also love a graph that shows a trend going up and to the right.

![538 predicts Cubs Winning 2016 World Series](/static/paine-cubs-1.jpg?raw=true)

Go Cubs! (Source: [There's an 85 Percent Chance...](https://fivethirtyeight.com/features/theres-an-85-percent-chance-the-cubs-wont-win-the-world-series-next-year-either/))

### Other Works Cited

* [fermyon/wagi-ruby](https://github.com/fermyon/wagi-ruby)

To learn how pure Ruby Gem dependencies can be included in Wasm modules and get
this work off the ground without too much pain, I cloned the above repository.

* [fermyon.com/wasm-languages/ruby](https://www.fermyon.com/wasm-languages/ruby)

A bit more guided-tour than the above, but does not cover requiring Ruby gems.
Loads of interesting threads can be found in the "Learn More" section below it.

[Example 1]: wasm-ex1#example-1
[Example 2]: wasm-ex2#prelude-for-example-2
[Example 3]: wasm-ex3#prelude-for-example-3
