import 'dart:convert';

import 'package:http/http.dart' as http;

/**
 * Jack API
 * 
 * Eventually will be a library of non-authenticated
 * functions that will search or scrape for matrix
 * servers for Syphon
 * 
 */
class JackApi {
  static const fetchPublicServersEndpoint =
      'https://www.hello-matrix.net/public_servers.php?format=json&only_public=true&show_from=United+States+(Denver)';

  /**
   * Fetch Public Homeservers (hello matrix)
   * 
   * Returns an array of homeseerver objects
   */
  static Future<dynamic> fetchPublicServers() async {
    String url = fetchPublicServersEndpoint;

    Map<String, String> headers = {
      // 'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }
}

// // WARNING: ONLY FOR TESTING OUTPUT
// Future<String> get _localPath async {
//   final directory = await getApplicationDocumentsDirectory();

//   return directory.path;
// }

// // WARNING: ONLY FOR TESTING OUTPUT
// Future<File> get _localFile async {
//   final path = await _localPath;
//   return File('$path/matrix.json');
// }

// // WARNING: ONLY FOR TESTING OUTPUT
// Future<dynamic> readFullSyncJson() async {
//   try {
//     final file = await _localFile;
//     String contents = await file.readAsString();
//     return await jsonDecode(contents);
//   } catch (error) {
//     // If encountering an error, return 0.
//     debugPrint('[readFullSyncJson] $error');
//     return null;
//   } finally {
//     debugPrint('** Read State From Disk Successfully **');
//   }
// }
