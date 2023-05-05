#!/bin/bash

show_limits=false
list_only=false

print_usage() {
  echo "Usage: $0 [-c client_id] [-l] [-s] imgur_url"
  echo "  -c, --client-id    Client ID for accessing the Imgur API (can also be set with the IMGUR_CLIENT_ID environment variable)"
  echo "  -l, --list-only    Only list the URLs of the images instead of downloading them"
  echo "  -s, --show-limits  Show the remaining rate limit information"
  echo "  -h, --help         Print this message."
}

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -c|--client-id)
      CLIENT_ID="$2"
      shift
      shift
      ;;
    -l|--list-only)
      list_only=true
      shift
      ;;
    -s|--show-limits)
      show_limits=true
      shift
      ;;
    *)
      IMGUR_URL="$1"
      shift
      ;;
  esac
done

if [ -z "$IMGUR_URL" ]; then
  echo "Error: no Imgur URL provided"
  print_usage
  exit 1
fi

if [ -z "$CLIENT_ID" ]; then
  CLIENT_ID="$IMGUR_CLIENT_ID"
fi

if [ -z "$CLIENT_ID" ]; then
  echo "Error: no client ID provided (use -c or set IMGUR_DL_CLIENT_ID environment variable)"
  print_usage
  exit 1
fi

response=$(curl -s -i -H "Authorization: Client-ID $CLIENT_ID" "https://api.imgur.com/3/album/$(basename $IMGUR_URL)/images")
headers=$(echo "$response" | awk '/^\r$/ {exit} {print}')
body=$(echo "$response" | awk 'BEGIN {skip=1} /^\r$/ {skip=0; next} skip {next} {print}')


if [ "$show_limits" = true ]; then
  limit=$(echo "$headers" | grep -i '^x-ratelimit-clientlimit:' | awk '{gsub(/\r/,""); print $2}')  
  remaining=$(echo "$headers" | grep -i '^x-ratelimit-clientremaining:' | awk '{gsub(/\r/,""); print $2}')
  echo "Remaining daily requests: ${remaining} of ${limit} request/day."
fi

if [ "$list_only" = true ]; then
  echo $body | jq -r '.data[].link'
else
  echo $body | jq -r '.data[].link' | xargs -n 1 curl -O
fi
