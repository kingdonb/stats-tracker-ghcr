// Adapted from:
// https://github.com/wasmerio/wasmer-ruby
// wasmer-ruby/examples/appendices/wasi.rs
// Compiled to Wasm by using the Makefile
// (it runs cargo build!)

use wasm_bindgen::prelude::*;
use std::{env, fs};
// extern crate scraper;

struct X {
    i: i32,
}

#[wasm_bindgen]
pub fn count_from_html() -> i32 {
    let mut arguments = env::args().collect::<Vec<String>>();

    println!("Found program name: `{}`", arguments[0]);

    arguments = arguments[1..].to_vec();
    println!(
        "Found {} arguments: {}",
        arguments.len(),
        arguments.join(", ")
    );

    let file_source = &arguments[0];

    // Scraper using a mapped directory
    use scraper::{Html, Selector};

    // let contents = fs::read_to_string("/Users/kingdonb/w/stats-tracker-ghcr/lib/cache/content")
    //     .expect("Should have been able to read the file");
    // println!("With text:\n{contents}")

    let content = fs::read_to_string(file_source)
        .expect("No readable file was found there");

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
fn main() {
    // Let's learn to use scraper (without any file at first)
    // {
    //     use scraper::{Html, Selector};

    //     let html = r#"
    //         <!DOCTYPE html>
    //         <meta charset="utf-8">
    //         <title>Hello, world!</title>
    //         <h1 class="foo">Hello, <i>world!</i></h1>
    //     "#;

    //     let document = Html::parse_document(&html);
    //     let selector = Selector::parse("title").unwrap();
    //     let title = document.select(&selector).next().unwrap();

    //     let text = title.text().collect::<Vec<_>>()[0];
    //     println!("Found title: `{}`", text)
    // }

    // Arguments
    {
        let mut arguments = env::args().collect::<Vec<String>>();

        println!("Found program name: `{}`", arguments[0]);

        arguments = arguments[1..].to_vec();
        println!(
            "Found {} arguments: {}",
            arguments.len(),
            arguments.join(", ")
        );

        let file_source = &arguments[0];

        // Scraper using a mapped directory
        use scraper::{Html, Selector};

        // let contents = fs::read_to_string("/Users/kingdonb/w/stats-tracker-ghcr/lib/cache/content")
        //     .expect("Should have been able to read the file");
        // println!("With text:\n{contents}")

        let content = fs::read_to_string(file_source)
            .expect("No readable file was found there");

        let document = Html::parse_document(&content);
        let selector = Selector::parse("#repo-content-turbo-frame > div > div > div > div.d-flex.flex-column.flex-md-row.mt-n1.mt-2.gutter-condensed.gutter-lg.flex-column > div.col-12.col-md-3.flex-shrink-0 > div:nth-child(3) > div.container-lg.my-3.d-flex.clearfix > div.lh-condensed.d-flex.flex-column.flex-items-baseline.pr-1").unwrap();
        for element in document.select(&selector) {
            let t = element;
            let h3 = Selector::parse("h3").unwrap();
            for counter in t.select(&h3) {
                let count = counter.value().attr("title").unwrap();
                println!("Text: {:?}", count);
            }
        }
    }
}
