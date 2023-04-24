// Adapted from: 
// https://github.com/wasmerio/wasmer-ruby
// wasmer-ruby/examples/appendices/wasi.rs
// Compiled to Wasm by using the Makefile
// (it runs cargo build!)

use std::{env, fs};
// extern crate scraper;

fn main() {
    // Scraper
    {
        use scraper::Html;

        let html = r#"
            <!DOCTYPE html>
            <meta charset="utf-8">
            <title>Hello, world!</title>
            <h1 class="foo">Hello, <i>world!</i></h1>
        "#;

        let _document = Html::parse_document(html);
    }
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
    }

    // Environment variables
    {
        let environment_variables = env::vars()
            .map(|(arg, val)| format!("{}={}", arg, val))
            .collect::<Vec<String>>();

        println!(
            "Found {} environment variables: {}",
            environment_variables.len(),
            environment_variables.join(", ")
        );
    }

    // Directories.
    {
        let root = fs::read_dir("/")
            .unwrap()
            .map(|e| e.map(|inner| format!("{:?}", inner)))
            .collect::<Result<Vec<String>, _>>()
            .unwrap();

        println!(
            "Found {} preopened directories: {}",
            root.len(),
            root.join(", ")
        );
    }
}
