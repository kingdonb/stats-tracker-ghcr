.PHONY: all test tidy clean distclean
all: stat.wasm test

test: stat.wasm
	ruby test.rb
stat.raw.wasm: stat/src/main.rs
	cd stat && cargo build --release --target wasm32-wasi && \
	cp -f target/wasm32-wasi/release/stat.wasm ../stat.raw.wasm
	wasm-strip stat.raw.wasm

stat.wasm: stat.raw.wasm
	wasm-opt -O4 -Oz --enable-bulk-memory stat.raw.wasm -o stat.wasm

tidy:
	rm -f stat.raw.wasm

clean: tidy
	rm -f stat.wasm

distclean: clean
	rm -rf stat/target
