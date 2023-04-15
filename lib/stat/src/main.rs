// Adapted from:
// https://github.com/wasmerio/wasmer-ruby
// wasmer-ruby/examples/appendices/wasi.rs
// Compiled to Wasm by using the Makefile
// (it runs cargo build!)

use std::{env, fs};
use lib_stat::count_from_html;


// use count_from_html;
//use stat::count_from_html;
// extern crate scraper;

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

        // println!("Found program name: `{}`", arguments[0]);

        arguments = arguments[1..].to_vec();
        // println!(
        //     "Found {} arguments: {}",
        //     arguments.len(),
        //     arguments.join(", ")
        // );

        let file_source = &arguments[0];

        // let contents = fs::read_to_string("/Users/kingdonb/w/stats-tracker-ghcr/lib/cache/content")
        //     .expect("Should have been able to read the file");
        // println!("With text:\n{contents}")

        let content = fs::read_to_string(file_source)
            .expect("No readable file was found there");

        let count = count_from_html(content);
        println!("{:?}", count);
    }
}
