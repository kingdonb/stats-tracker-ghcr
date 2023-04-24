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

        // let contents = fs::read_to_string("/Users/kingdonb/w/stats-tracker-ghcr/lib/cache/content")
        //     .expect("Should have been able to read the file");
        // println!("With text:\n{contents}")

        let content = fs::read_to_string(file_source)
            .expect("No readable file was found there");

        let count = count_from_html(content);
        println!("{:?}", count);
    }

    // We don't need any Environment variables
    // // Environment variables
    // {
    //     let environment_variables = env::vars()
    //         .map(|(arg, val)| format!("{}={}", arg, val))
    //         .collect::<Vec<String>>();

    //     println!(
    //         "Found {} environment variables: {}",
    //         environment_variables.len(),
    //         environment_variables.join(", ")
    //     );
    // }

    // We will borrow content from within a Directory, as in:
    // // Directories.
    // {
    //     let root = fs::read_dir("/")
    //         .unwrap()
    //         .map(|e| e.map(|inner| format!("{:?}", inner)))
    //         .collect::<Result<Vec<String>, _>>()
    //         .unwrap();

    //     println!(
    //         "Found {} preopened directories: {}",
    //         root.len(),
    //         root.join(", ")
    //     );
    // }
}
