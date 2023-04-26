# Prelude for Example 3

The goal of this example is to some meaningful work with a WebAssembly module.
We'll finish our Stats Tracker application for GHCR packages, and implement a
deployment of it for the FluxCD organization that runs on Kubernetes somehow.

In the [previous][Example 1] two [examples][Example 2] we explored the problem
of how to run Wasm with Ruby, and finding out how does reasonable architecture
look like when combining these two technologies.

Now let's implement from the best of what we have learned, and finally build
the [Stats Tracker][] for GHCR!

And let's not forget to compare the performance according to our benchmarking
test matrix, from [Example 2][Additional Comparison]:

```
              Native C   Ruby   Rust   Wat2wasm
            +----------+------+------+----------+
Hello World |          |  XX  |  XX  |    XX    |
            +----------|------|------|----------+
HTML Parser |    XX    |  XX  |  XX  |          +
            +----------+------+------+----------+
```

TODO: Be sure to include a QR code from [syrusakbary/qr2text][]

(Here's one)


    █▀▀▀▀▀█  ▀▄▀ ██▄██▀▀█▀ ▀  █▀▀▀▀▀█
    █ ███ █ █▀▄█▀▀▄▄▄▀▀▄▄▀█ ▄ █ ███ █
    █ ▀▀▀ █ ██▀▄▀ ▄█▄█▀ ▄▀▀▀▄ █ ▀▀▀ █
    ▀▀▀▀▀▀▀ █▄█ █ ▀▄▀ █ ▀▄▀ █ ▀▀▀▀▀▀▀
    █▄▀███▀▄  █  ▀▀▀█▀▄▄▄▄ █  ██▀██ ▄
      ▀▀▀ ▀▀  ██▄ ▄▀█ ▀▄▀▄  █▄█ █▄█▄▄
    █▀▀█ █▀▄▄▄▀ ▄ ▄▄▄ ▀▀▄▀ █▀▀▄▀▀█ ▄▄
    ▄ █ ▄ ▀█▄ ▀▀▀   ▄▀ █▄▄▀▄ ██▄▀██▀
    ▀▄▀ ▀▀▀███ ▀▄ ▀  █▄█▄ ▀▄▀▀▄█▀█▄▄█
    █▀▀▀ █▀▄█ ▀█▀▄▀▀ █▄▄█ ▀ ▀█ ██▄█▀
    ▄ ▀  ▀▀▀     █▄█▀ ▄▀▀█▀▄▀█▄▀▀█▄▀▄
    █ ▄█▀ ▀▀ ▄█▄▀▀██▀ ▄ ▀▄▄  █▄▄ ▄█▀▄
    ▀ ▀ ▀▀▀▀█▄▄ ███▀▄▀▄▄ ▄▀██▀▀▀█▀▄██
    █▀▀▀▀▀█ ▄ ▀▀ █▄▀▄ ▀ ██▄██ ▀ █▄██
    █ ███ █ █ ▀ █ ▄▄▄▄▀▀▄▀▄▄██▀▀█▀▄ ▄
    █ ▀▀▀ █ ▀ ▀█ ██ ▄▀ █▄▄█   ▀▀▄▄▄
    ▀▀▀▀▀▀▀ ▀  ▀ ▀   ▀ ▀  ▀ ▀ ▀▀   ▀

If you enjoyed the talk so far, scan this QR code and find the GitHub page! Or
feel free to take picture and use to come back later. I hope we are having fun.

## Example 3

### Kubernetes and Helm

We're about to mix Spin with Rails, on Kubernetes. All with Helm. I'm totally
serious about this. All deployed continuous delivery style, with Weave GitOps!


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

Source: [opensource.com][]

## Run Wasm in Browser

## Run Wasm in Ruby

### Limitations

TODO

#### Performance

TODO

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

### Further Exploration


🏏⚡️⚾️🔥




[Example 1]: ../wasm-ex1
[Example 2]: ../wasm-ex2
[Stats Tracker]: ../
[Additional Comparison]: ../wasm-ex2#additional-comparison
[syrusakbary/qr2text]: https://wapm.io/syrusakbary/qr2text

[opensource.com]: https://opensource.com/article/21/3/hello-world-webassembly
