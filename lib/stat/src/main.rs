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

    // Scraper
    {
        use scraper::{Html, Selector};

        let content = fs::read_dir("/html")
        .unwrap()
        .map(|e| e.map(|inner| format!("{:?}", inner)))
        .collect::<Result<Vec<String>, _>>()
        .unwrap();

        let html = content;

        let document = Html::parse_document(html);
        let selector = Selector::parse("#repo-content-turbo-frame > div > div > div > div.d-flex.flex-column.flex-md-row.mt-n1.mt-2.gutter-condensed.gutter-lg.flex-column > div.col-12.col-md-3.flex-shrink-0 > div:nth-child(3) > div.container-lg.my-3.d-flex.clearfix > div.lh-condensed.d-flex.flex-column.flex-items-baseline.pr-1").unwrap();
        let _count = document.select(&selector).next().unwrap();
    }
}
