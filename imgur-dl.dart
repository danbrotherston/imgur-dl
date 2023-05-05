import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void main(List<String> args) async {
  var showLimits = false;
  var listOnly = false;
  var link = '';
  var clientId = Platform.environment['CLIENT_ID'];
  if (clientId == null) {
    print('Please set CLIENT_ID environment variable');
    exit(1);
  }

  // parse command line arguments
  for (var arg in args) {
    if (arg == '-s' || arg == '--show-limits') {
      showLimits = true;
    } else if (arg == '-l' || arg == '--list') {
      listOnly = true;
    } else {
      link = arg;
    }
  }

  if (link == '') {
    print('Please provide a link to an Imgur image as a command line argument');
    exit(1);
  }

  if (listOnly) {
    var response = await http.get(Uri.parse(link));
    var data = jsonDecode(response.body);
    for (var image in data['data']) {
      print(image['link']);
    }
    exit(0);
  }

  // make API request to Imgur to get image data
  var url = Uri.parse(link + '.json');
  var response = await http.get(url, headers: {'Authorization': 'Client-ID $clientId'});

  // check rate limit status
  var clientLimit = response.headers['x-ratelimit-clientlimit'];
  var clientRemaining = response.headers['x-ratelimit-clientremaining'];
  if (showLimits && clientLimit != null && clientRemaining != null) {
    print('Remaining requests today: $clientRemaining / $clientLimit');
  }

  // parse response and download image
  var data = jsonDecode(response.body);
  var imageUrl = data['data']['link'];
  var imageName = imageUrl.split('/').last;
  var imageResponse = await http.get(Uri.parse(imageUrl));
  var file = File(imageName);
  await file.writeAsBytes(imageResponse.bodyBytes);
  print('Image saved as $imageName');
}
