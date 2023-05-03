#!/usr/bin/env tclsh

package require http
package require tls
package require json

set api_url "https://api.imgur.com/3/image/"
set usage "Usage: imgur-dl.tcl \[-h\] \[-s\] \[-l\] \[-c CLIENT_ID\] image_url"

::http::register https 443 ::tls::socket

set image_url ""

set options {}
set usage "Usage: imgur-dl.tcl \[-s\] \[-l\] \[-h\] \[-c <CLIENT_ID>\] <imgur_url>\n"

set client_id ""
set c_id_next false

foreach arg $argv {
    switch -- $arg {
        "-h" { puts $usage; exit }
        "-s" { lappend options -s }
        "-l" { lappend options -l }
        "-c" { lappend options -c; set c_id_next true }
        default {
            if { $c_id_next } {
                set client_id $arg
                set c_id_next false
            } else {
                set image_url $arg
            }
        }
    }
}

if {$image_url eq ""} {
    puts "Error: Imgur url not provided."
    puts $usage
    exit
}

# If CLIENT_ID not provided via command line, read from environment variable
if { [lsearch $options -c] == -1 } {
    set client_id $env(IMGUR_CLIENT_ID)
}

if { $client_id eq "" } {
    puts "Error: IMGUR_CLIENT_ID environment variable not set and CLIENT_ID flag not used."
    puts $usage
    exit 1
}

set imgur_album [lindex [split $image_url "/"] end]

puts "Using $client_id to retrieve images from album $imgur_album"

dict set headers Authorization "Client-ID $client_id"
set response [::http::geturl "https://api.imgur.com/3/album/$imgur_album/images" -headers $headers]
set json_data [json::json2dict [::http::data $response]]
set images [dict get $json_data data]

set img_urls {}

foreach element $images {
    lappend img_urls [dict get $element link]
}

# If -s flag provided, show remaining API limits and exit
if { [lsearch $options -s] != -1 } {
    set response_headers [::http::meta $response]
    puts "Limits: [dict get $response_headers x-ratelimit-clientremaining] remaining of [dict get $response_headers x-ratelimit-clientlimit] requests per day"
}

::http::cleanup $response

# If -l flag provided, list the image URLs and exit
if { [lsearch $options -l] != -1} {
    foreach img_url $img_urls {
        puts $img_url
    }
} else {
    foreach img_url $img_urls {
        puts "Downloading $img_url ..."
        # Download images
        set image_data [::http::geturl $img_url]

        # Save the image to disk
        set filename [lindex [split $img_url "/"] end]
        set f [open $filename "wb"]
        fconfigure $f -translation binary
        puts $f [::http::data $image_data]
        close $f
        ::http::cleanup $image_data
    }

    puts "Downloaded [llength $img_urls] images."
}