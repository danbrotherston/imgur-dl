#!/usr/bin/env lua

local http = require("socket.http")
local ltn12 = require("ltn12")
local argparse = require("argparse")

-- Create a command-line argument parser
local parser = argparse()
    :name("imgur-dl.lua")
    :description("A tool to download images from Imgur.")
parser:argument("url")
    :description("The URL of the Imgur image to download.")
parser:option("-c --client-id")
    :description("Your Imgur API client ID.")
parser:flag("-l --list")
    :description("List the URLs of the images instead of downloading them.")
parser:flag("-s --show-limits")
    :description("Show the remaining requests for the Imgur API.")
parser:flag("-v --version")
    :description("Print the version number of the tool.")
    :action(function() print("imgur-dl.lua v1.0.0") os.exit() end)

-- Parse the command-line arguments
local args = parser:parse()

-- Check if client ID is provided as a command-line argument
local client_id = args["client_id"]
if not client_id then
    -- If not provided, check if the CLIENT_ID environment variable is set
    client_id = os.getenv("IMGUR_CLIENT_ID")
end

-- Check if client ID is present
if not client_id then
    print("Error: Imgur API client ID not provided, ether provide a IMGUR_CLIENT_ID env variable or use -c|--client-id option.")
    os.exit(1)
end

-- Make the HTTP request to Imgur API
local url = args["url"]
local headers = {
    ["Authorization"] = "Client-ID " .. client_id
}

local imgur_album = url:match("/(%w+)$")
print("Requesting album: " .. imgur_album .. "...")
local response_body = {}
local success, status_code, headers, status_string = http.request{
    url = "https://api.imgur.com/3/album/" .. imgur_album .. "/images",
    headers = headers,
    sink = ltn12.sink.table(response_body)
}

-- Check if the API request was successful
if not success then
    print("Error: Failed to make API request: " .. status_string)
    os.exit(1)
end

-- Decode the JSON response
local json = require("json")
local response = json.decode(table.concat(response_body))

-- Check if the API returned an error
if not response["success"] then
    print("Error: " .. response["data"]["error"])
    os.exit(1)
end

-- Print the remaining API requests
if args["show_limits"] then
    print("Remaining requests today: " .. headers["x-ratelimit-clientremaining"])
    print("Total requests per day: " .. headers["x-ratelimit-clientlimit"])
end

local urls = {}
for _, imgdata in ipairs(response["data"]) do
    table.insert (urls, imgdata['link'])
end

-- Download the image or list the URLs
if args["list"] then
    print (table.concat(urls, "\n"))
else
    for _, url in ipairs(urls) do
        -- Extract the filename from the URL
        local filename = url:match("/([%w.]+)$")
        -- Download the image to the current directory
        local file = io.open(filename, "wb")
        local success, status_code, headers, status_string = http.request{
            url = url,
            sink = ltn12.sink.file(file)
        }
        if not success then
            print("Error: Failed to download image.")
            os.exit(1)
        end
        print("Downloaded " .. filename)
    end
end
