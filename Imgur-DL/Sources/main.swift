import Foundation
import ArgumentParser
import SystemPackage

struct ImgurDownload: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "Imgur-DL",
        abstract: "Download images from Imgur URLs using the Imgur API",
        version: "0.1.0",
        subcommands: [],
        defaultSubcommand: nil)

    @Argument(help: "The Imgur URL(s) to download images from")
    var urls: [String]

    @Flag(name: .shortAndLong, help: "Print the list of image URLs without downloading them")
    var list: Bool = false

    @Flag(name: .shortAndLong, help: "Show the remaining requests limit")
    var showLimits: Bool = false

    @Option(name: .shortAndLong, help: "The Imgur API client ID")
    var clientId: String?

    func run() throws {
        let clientId = self.clientId ?? ProcessInfo.processInfo.environment["IMGUR_CLIENT_ID"]
        guard let clientId = clientId else {
            print("No client ID provided. Please set the IMGUR_CLIENT_ID environment variable or use the -c/--client-id option.")
            throw ExitCode.validationFailure
        }

        for url in urls {
            let endpoint = "https://api.imgur.com/3/album/\(url.components(separatedBy: "/").last!)/images"
            let headers = ["Authorization": "Client-ID \(clientId)"]

            guard let url = URL(string: endpoint) else {
                print("Invalid Imgur album URL: \(url)")
                throw ExitCode.validationFailure
            }

            let (response, data) = try URLSession(configuration: URLSessionConfiguration.default)
                .synchronousDataTask(with: url, headers: headers)
            let decoder = JSONDecoder()

            guard let images = try decoder.decode(GalleryAlbum.self, from: data).data?.images else {
                print("Failed to decode response from Imgur API")
                throw ExitCode.failure
            }

            if list {    
                images.forEach { print($0.link) }
            } else {
                for image in images {
                    guard let url = URL(string: image.link) else {
                        print("Invalid Imgur API image link: \(image.link)")
                        continue
                    }

                    guard let (response, imgData) = try URLSession(configuration: URLSessionConfiguration.default)
                            .synchronousDataTask(with: url) else {
                        print("Failed to get response from Imgur.")
                        continue
                    }

                    let fileName = image.link.components(separatedBy: "/").last!

                    guard let fileURL = FileManager.default.urls(for: .currentDirectoryInDomain, in: .userDomainMask).first?.appendingPathComponent(fileName) else {
                        print("Failed to create file URL")
                        throw ExitCode.failure
                    }

                    debugPrint(fileUrl)

                    print("Downloaded image: \(fileName)")
                }
            }

            if showLimits {
                guard let clientLimit = response.value(forHTTPHeaderField: "x-ratelimit-clientlimit"),
                      let clientRemaining = response.value(forHTTPHeaderField: "X-RateLimit-ClientRemaining") else {
                    print("Failed to get rate limit information from response headers")
                }

                print("Remaining requests: \(clientRemaining) of \(clientLimit)")
            }
        }
    }
}

struct GalleryAlbum: Codable {
    let data: GalleryAlbumData?
}

struct GalleryAlbumData: Codable {
    let images: [Image]?
}

struct Image: Codable {
    let link: String
}

extension URLSession {
    func synchronousDataTask(with url: URL, headers: [String: String] = [:]) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?

        let semaphore = DispatchSemaphore(value: 0)

        let dataTask = self.dataTask(with: url, headers: headers) {
            data = $0
            response = $1
            error = $2

            semaphore.signal()
        }
        dataTask.resume()

        _ = semaphore.wait(timeout: .distantFuture)

        return (data, response, error)
    }
}