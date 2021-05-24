import 'dart:convert';

import 'package:http/http.dart' as http;

/// Jack API
/// 
/// Eventually will be a library of non-authenticated
/// functions that will search or scrape for matrix
/// servers for Syphon
/// 
class JackApi {
  static const List<String> endpoints = [
    'https://www.hello-matrix.net/public_servers.php?format=json&only_public=true&show_from=United+States+(Denver)',
  ];
  /// Fetch Public Homeservers (hello matrix)
  /// 
  /// Returns an array of homeseerver objects
  static Future<dynamic> fetchPublicServers() async {
    final String url = endpoints.elementAt(0);

    final response = await http.get(Uri.parse(url));

    return await json.decode(response.body);
  }
}
