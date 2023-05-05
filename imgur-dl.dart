import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

import 'package:http/http.dart' as http;

void main(List<String> args) async {
  var showLimits = false;
  var listOnly = false;
  var link = '';
  var clientId = Platform.environment['IMGUR_CLIENT_ID'];

  var next_is_cid = false;

  // parse command line arguments
  for (var arg in args) {
    if (arg == '-s' || arg == '--show-limits') {
      showLimits = true;
    } else if (arg == '-l' || arg == '--list') {
      listOnly = true;
    } else if (arg == '-c' || arg == '--client-id') {
      next_is_cid = true;
    } else {
      if (next_is_cid) {
        clientId = arg;
      } else {
        link = arg;
      }
    }
  }

  if (clientId == null) {
    print(
        'Client ID not set: Please set IMGUR_CLIENT_ID environment variable or use -c|--client-id option.');
    exit(1);
  }

  if (link == '') {
    print(
        'Please provide a link to an Imgur image or album as a command line argument');
    exit(1);
  }

  // make API request to Imgur to get image data
  final url =
      Uri.parse("https://api.imgur.com/3/album/${basename(link)}/images");
  final response =
      await http.get(url, headers: {'Authorization': 'Client-ID $clientId'});

  // check rate limit status
  final clientLimit = response.headers['x-ratelimit-clientlimit'];
  final clientRemaining = response.headers['x-ratelimit-clientremaining'];
  if (showLimits && clientLimit != null && clientRemaining != null) {
    print('Remaining requests today: $clientRemaining / $clientLimit');
  }

  final imgurAlbumData = jsonDecode(response.body);
  final imgUrls = imgurAlbumData['data'].map((x) => x['link']);

  if (listOnly) {
    print(imgUrls.join('\n'));
  } else {
    for (var imageUrl in imgUrls) {
      final imageName = imageUrl.split('/').last;
      final imageResponse = await http.get(Uri.parse(imageUrl));
      final file = File(imageName);
      await file.writeAsBytes(imageResponse.bodyBytes);
      print('Image saved as $imageName');
    }
  }
}
