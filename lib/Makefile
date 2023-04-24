all: stat.wasm
stat.raw.wasm: stat.rs
	cd stat && cargo build --release --target wasm32-wasi && \
	cp -f target/wasm32-wasi/release/stat.wasm ../stat.raw.wasm
	wasm-strip stat.raw.wasm

stat.wasm: stat.raw.wasm
	wasm-opt -O4 -Oz --enable-bulk-memory stat.raw.wasm -o stat.wasm

clean:
	rm -f stat.raw.wasm

distclean: clean
	rm -f stat.wasm
