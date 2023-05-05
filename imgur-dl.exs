#!/usr/bin/env elixir

defmodule ImgurDL do
  use HTTPoison.Base

  def process_url(url, options) do
    client_id = System.get_env("CLIENT_ID")

    headers = [{"Authorization", "Client-ID #{client_id}"}]

    case options[:show_limits] do
      true -> IO.puts("Retrieving rate limit information...")
      _ -> nil
    end

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Jason.decode(body) do
          {:ok, json} ->
            case options[:list] do
              true ->
                for item <- json["data"] do
                  IO.puts(item["link"])
                end
              _ ->
                case json["data"]["link"] do
                  nil ->
                    IO.puts("No image found.")
                  link ->
                    case HTTPoison.get(link) do
                      {:ok, %HTTPoison.Response{body: body}} ->
                        IO.puts("Downloading image...")
                        File.write("imgur_image.jpg", body)
                      {:error, _} ->
                        IO.puts("Error downloading image.")
                    end
                end
            end

            case options[:show_limits] do
              true ->
                client_remaining = HTTPoison.get_header(json, "X-RateLimit-ClientRemaining")
                client_limit = HTTPoison.get_header(json, "X-RateLimit-ClientLimit")

                IO.puts("Remaining requests: #{client_remaining} / #{client_limit}")
              _ -> nil
            end
          {:error, _} ->
            IO.puts("Error parsing JSON.")
        end
      {:error, _} ->
        IO.puts("Error retrieving image.")
    end
  end
end

args = System.argv()
options = OptionParser.parse(args, [list: :boolean, show_limits: :boolean])

case args do
  [url] -> ImgurDL.process_url(url, options)
  _ -> IO.puts("Usage: imgur-dl.exs [OPTIONS] URL")
end
