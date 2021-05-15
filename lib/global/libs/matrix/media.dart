// Dart imports:
import 'dart:async';
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

/**
 * Media queries for matrix
 * 
 * Testing out using a "params map"
 * as the default to allow calling from
 * a non-ui thread
 */
class Media {
  static Future<dynamic> fetchThumbnail(Map params) async {
    String? protocol = params['protocol'];
    String? homeserver = params['homeserver'];
    String? accessToken = params['accessToken'];
    String? serverName = params['serverName'];
    String mediaUri = params['mediaUri'];

    return await fetchThumbnailUnmapped(
      protocol: protocol,
      homeserver: homeserver,
      accessToken: accessToken,
      serverName: serverName,
      mediaUri: mediaUri,
      method: params['method'] ?? 'crop',
      size: params['size'] ?? 52,
    );
  }

  static Future<dynamic> fetchThumbnailUnmapped({
    String? protocol = 'https://',
    String? homeserver = 'matrix.org',
    String? accessToken,
    String? serverName,
    required String mediaUri,
    String method = 'crop',
    int size = 52,
  }) async {
    List<String> mediaUriParts = mediaUri.split('/');

    // Parce the mxc uri for the server location and id
    String mediaId = mediaUriParts[mediaUriParts.length - 1];
    String mediaServer = serverName ?? mediaUriParts[mediaUriParts.length - 2];

    String url =
        '$protocol$homeserver/_matrix/media/r0/thumbnail/$mediaServer/$mediaId';

    // Params
    url += '?height=${size}&width=${size}&method=${method}';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.headers['content-type'] == 'application/json') {
      final errorData = await json.decode(response.body);
      throw errorData['error'];
    }

    return {"bodyBytes": response.bodyBytes};
  }

  static Future<dynamic> uploadMedia({
    String? protocol = 'https://',
    String? homeserver = 'matrix.org',
    String? accessToken,
    String? fileName,
    String fileType = 'application/jpeg', // Content-Type: application/pdf
    required Stream<List<int>> fileStream,
    int? fileLength,
  }) async {
    String url = '$protocol$homeserver/_matrix/media/r0/upload';

    // Params
    url += fileName != null ? '?filename=$fileName' : '';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': '$fileType',
      'Content-Length': '$fileLength',
    };

    // POST StreamedRequest for uploading byteStream
    final request = new http.StreamedRequest(
      'POST',
      Uri.parse(url),
    );

    request.headers.addAll(headers);
    fileStream.listen(request.sink.add, onDone: () => request.sink.close());

    // Attempting to await the upload response successfully
    final mediaUploadResponseStream = await request.send();
    final mediaUploadResponse = await http.Response.fromStream(
      mediaUploadResponseStream,
    );

    return json.decode(mediaUploadResponse.body);
  }
}

dynamic buildMediaDownloadRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String? accessToken,
  String? serverName,
  required String mediaUri,
}) {
  final List<String> mediaUriParts = mediaUri.split('/');
  final String mediaId = mediaUriParts[mediaUriParts.length - 1];
  final String mediaOrigin = serverName ?? homeserver;
  final String url =
      '$protocol$homeserver/_matrix/media/r0/download/$mediaOrigin/$mediaId';

  Map<String, String> headers = {
    'Authorization': 'Bearer $accessToken',
  };

  return {
    'url': Uri.parse(url),
    'headers': headers,
  };
}

/**
 * https://matrix.org/docs/spec/client_server/latest#id392
 * 
 * Upload some content to the content repository.
 */
dynamic buildMediaUploadRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String? accessToken,
  String? fileName,
  String fileType = 'application/jpeg', // Content-Type: application/pdf
  int? fileLength,
}) {
  String url = '$protocol$homeserver/_matrix/media/r0/upload';

  // Params
  url += fileName != null ? '?filename=$fileName' : '';

  Map<String, String> headers = {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': '$fileType',
    'Content-Length': '$fileLength',
  };

  return {
    'url': Uri.parse(url),
    'headers': headers,
  };
}
