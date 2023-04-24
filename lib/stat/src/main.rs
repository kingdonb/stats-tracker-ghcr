// Adapted from:
// https://github.com/wasmerio/wasmer-ruby
// wasmer-ruby/examples/appendices/wasi.rs
// Compiled to Wasm by using the Makefile
// (it runs cargo build!)

use std::{fs};
// extern crate scraper;

fn main() {
    // Let's learn to use scraper (without any file at first)
    // {
    //     use scraper::{Html, Selector};

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
