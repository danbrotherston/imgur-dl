extern crate clap;
extern crate reqwest;
extern crate serde;
extern crate serde_json;

use clap::{App, Arg};
use serde::Deserialize;

#[derive(Deserialize)]
struct ImgurAlbumResponse {
    data: Vec<ImgurImage>,
}

#[derive(Deserialize)]
struct ImgurImageResponse {
    data: ImgurImage,
}

#[derive(Deserialize)]
struct ImgurImage {
    link: String,
}

fn main() {
    let matches = App::new("imgur-scraper")
        .version("0.1.0")
        .author("Your Name <you@example.com>")
        .about("Downloads images from Imgur")
        .after_help("Please set the environment variable IMGUR_CLIENT_ID to a valid Imgur API client ID acquired by registering an API app on the Imgur website.")
        .arg(
            Arg::with_name("LIST")
                .short('l')
                .long("list")
                .help("Lists the URLs of the images without downloading them"),
        )
        .arg(
            Arg::with_name("IMAGE_LINK")
                .required(true)
                .index(1)
                .help("The link to the Imgur album or image to download"),
        )
        .arg(
            Arg::with_name("CLIENT_ID")
                .short('c')
                .long("client-id")
                .help("The client ID for the imgur API to override the env variable")
                .takes_value(true)
                .required(false),
        )
        .arg(
            Arg::with_name("SHOW_LIMIT")
                .short('s')
                .long("show-limit")
                .help("Display the remaining API limits")
                .takes_value(false),
        )
        .get_matches();

    let image_link = matches.value_of("IMAGE_LINK").unwrap();
    let album = image_link.contains("/a/");
    let hash = image_link.split("/").last().unwrap();

    let endpoint = if album {
        format!("https://api.imgur.com/3/album/{}/images", hash)
    } else {
        format!("https://api.imgur.com/3/image/{}", hash)
    };

    let client_id = match matches.value_of("CLIENT_ID") {
        Some(id) => id.to_string(),
        None => match std::env::var("IMGUR_CLIENT_ID") {
            Ok(val) => val,
            Err(_) => {
                eprintln!("error: client_id is required (either via --client-id flag or IMGUR_CLIENT_ID environment variable)");
                std::process::exit(1);
            }
        },
    };

    let client = reqwest::blocking::Client::new();
    let response = client
        .get(&endpoint)
        .header("Authorization", format!("Client-ID {}", client_id))
        .send()
        .expect("Failed to send request");

    if !response.status().is_success() {
        eprintln!("error: failed to fetch image from {}", endpoint);
        std::process::exit(1);
    }

    if matches.is_present("SHOW_LIMIT") {
        let client_limit = response
            .headers()
            .get("X-RateLimit-ClientLimit")
            .expect("Rate limit header not set.")
            .to_str()
            .unwrap();
        let client_remaining = response
            .headers()
            .get("X-RateLimit-ClientRemaining")
            .expect("Rate limit header not set.")
            .to_str()
            .unwrap();
        println!(
            "API limits: {} remaining of {} requests/day",
            client_remaining, client_limit
        );
    }

    let imgur_response: ImgurAlbumResponse = if album {
        serde_json::from_str(&response.text().unwrap()).unwrap()
    } else {
        let img_response: ImgurImageResponse =
            serde_json::from_str(&response.text().unwrap()).unwrap();
        ImgurAlbumResponse {
            data: vec![img_response.data],
        }
    };

    if matches.is_present("LIST") {
        for img in imgur_response.data {
            println!("{}", img.link);
        }
    } else {
        for img in imgur_response.data {
            if img.link.ends_with(".jpg") || img.link.ends_with(".png") {
                let filename = img.link.split("/").last().unwrap();
                let mut response = client
                    .get(&img.link)
                    .send()
                    .expect("Failed to download image");
                let mut file = std::fs::File::create(filename).expect("Failed to create file");
                std::io::copy(&mut response, &mut file).expect("Failed to save image");
                println!("Downloaded image: {}", filename);
            }
        }
    }
}
