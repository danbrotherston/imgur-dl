#!/usr/bin/env elixir

defmodule ImgurDL do
  use HTTPoison.Base

  def print_usage() do
    IO.puts("Usage: imgur-dl.exs [-c client_id] [-l] [-s] imgur_url")
    IO.puts("  -c, --client_id    Client ID for accessing the Imgur API (can also be set with the IMGUR_CLIENT_ID environment variable)")
    IO.puts("  -l, --list_only    Only list the URLs of the images instead of downloading them")
    IO.puts("  -s, --show_limits  Show the remaining rate limit information")
    IO.puts("  -h, --help         Print this message.")
  end

  def process_url(url, options) do
    client_id = System.get_env("IMGUR_CLIENT_ID")

    headers = [{"Authorization", "Client-ID #{client_id}"}]
    apiUrl = "https://api.imgur.com/3/album/#{Path.basename(url)}/images"

    case HTTPoison.get(apiUrl, headers) do
      {:ok, %HTTPoison.Response{body: body, headers: headers}} ->
        case Jason.decode(body) do
          {:ok, json} ->
            imgUrls = Enum.map(json["data"], fn item -> item["link"] end)

            case options[:list_only] do
              true ->
                IO.puts(Enum.join(imgUrls, "\n"))
              _ ->
                for imgUrl <- imgUrls do
                  case HTTPoison.get(imgUrl) do
                    {:ok, %HTTPoison.Response{body: body}} ->
                      IO.puts("Downloading image #{imgUrl}...")
                      File.write(Path.basename(imgUrl), body)
                    {:error, _} ->
                      IO.puts("Error downloading image #{imgUrl}.")
                  end
                end
            end

            case options[:show_limits] do
              true ->
                {_, client_remaining} = List.keyfind(headers, "x-ratelimit-clientremaining", 0)
                {_, client_limit} = List.keyfind(headers, "x-ratelimit-clientlimit", 0)

                IO.puts("Remaining requests: #{client_remaining} / #{client_limit}")
              _ -> nil
            end
          {:error, _} ->
            IO.puts("Error parsing JSON.")
        end
      {:error, _} ->
        IO.puts("Error retrieving album data.")
    end
  end
end

args = System.argv()
{options, args, invalid} = OptionParser.parse(args,
  switches: [list_only: :boolean, show_limits: :boolean, client_id: :string],
  aliases: [l: :list_only, s: :show_limits, c: :client_id])

case { args, invalid } do
  { [url], [] } -> ImgurDL.process_url(url, options)
  _ -> ImgurDL.print_usage()
end
