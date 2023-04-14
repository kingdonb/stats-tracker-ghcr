#!/usr/bin/env bash

time coproc ruby { wasmtime ruby.wasm 2>/dev/null ; }
echo "puts 'Hello'" >&${ruby[1]}
exec {ruby[1]}>&-
cat <&"${ruby[0]}"

# adapted from https://stackoverflow.com/a/15682270/661659
# & also from https://unix.stackexchange.com/a/86372/229312
