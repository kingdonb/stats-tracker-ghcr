// Adapted from:
// https://github.com/wasmerio/wasmer-ruby
// wasmer-ruby/examples/appendices/wasi.rs
// Compiled to Wasm by using the Makefile
// (it runs cargo build!)

// extern crate wasm_bindgen;
// use wasm_bindgen::prelude::*;

// extern crate scraper;

struct X {
    i: i32,
}

// #[wasm_bindgen]
// extern "C" {
//     fn html() -> String;
// }

// #[wasm_bindgen]
pub fn count_from_html(html: String) -> i32 {
    // Scraper using a mapped directory
    use scraper::{Html, Selector};

    let content = &html;

    let mut x = X { i: 0 };
    let document = Html::parse_document(&content);
    let selector = Selector::parse("#repo-content-turbo-frame > div > div > div > div.d-flex.flex-column.flex-md-row.mt-n1.mt-2.gutter-condensed.gutter-lg.flex-column > div.col-12.col-md-3.flex-shrink-0 > div:nth-child(3) > div.container-lg.my-3.d-flex.clearfix > div.lh-condensed.d-flex.flex-column.flex-items-baseline.pr-1").unwrap();
    for element in document.select(&selector) {
        let t = element;
        let h3 = Selector::parse("h3").unwrap();
        for counter in t.select(&h3) {
            let count = counter.value().attr("title").unwrap();
            x.i = count.parse::<i32>().unwrap();
        }
    }
    return x.i;
}
