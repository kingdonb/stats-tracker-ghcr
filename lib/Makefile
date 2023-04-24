all: stat.wasm
stat.raw.wasm: stat.rs
	rustc --target wasm32-wasi -O stat.rs -o stat.raw.wasm
	wasm-strip stat.raw.wasm

stat.wasm: stat.raw.wasm
	wasm-opt -O4 -Oz --enable-bulk-memory stat.raw.wasm -o stat.wasm

clean:
	rm stat.raw.wasm

distclean: clean
	rm stat.wasm
