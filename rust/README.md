# Imgur Downloader

Imgur Downloader is a command-line tool for downloading images from Imgur.
It downloads an album based on the web URL.

## Usage

`imgur-dl [FLAGS] [OPTIONS] <URL>`

### Arguments

 * URL: The URL of the Imgur image or album to download.

### Flags

 * -h, --help: Prints help information
 * -l, --list: Lists the URLs of all images in an Imgur album (requires an Imgur album URL).
 * -s, --show-limits: Shows the remaining rate limit for the Imgur API.

### Options

 * -c, --client-id <CLIENT_ID>: The Imgur API client ID (if not specified, the tool will read the IMGUR_CLIENT_ID environment variable).

## Examples

To download a images from an Imgur page:

`imgur-dl https://imgur.com/gallery/EvKve4K -c YOUR_CLIENT_ID`

To show the remaining rate limit for the Imgur API:

`imgur-dl <URL> -c YOUR_CLIENT_ID -s`

## Installation

To install Imgur Downloader, you need to have Rust installed. You can install Rust by following the instructions on the official Rust website: https://www.rust-lang.org/tools/install

Once you have Rust installed, you can install Imgur Downloader using Cargo, the Rust package manager. Open a terminal and run the following command:


`cargo install imgur-dl`

This will install the imgur-dl binary in your PATH.

## License

This tool is released under the [MIT License](https://opensource.org/licenses/MIT)