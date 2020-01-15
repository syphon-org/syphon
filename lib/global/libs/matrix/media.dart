dynamic buildThumbnailRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String serverName,
  String mediaUri,
  int size = 52,
  String method = 'crop',
}) {
  List<String> mediaUriParts = mediaUri.split('/');

  // Parce the mxc uri for the server location and id
  String mediaId = mediaUriParts[mediaUriParts.length - 1];
  String mediaServer = serverName ?? mediaUriParts[mediaUriParts.length - 2];

  String url =
      '$protocol$homeserver/_matrix/media/r0/thumbnail/${mediaServer ?? homeserver}/$mediaId';

  // Params
  url += '?height=${size}&width=${size}&method=${method}';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}

dynamic buildMediaDownloadRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String serverName,
  String mediaUri,
}) {
  List<String> mediaUriParts = mediaUri.split('/');
  String mediaId = mediaUriParts[mediaUriParts.length - 1];
  String url =
      '$protocol$homeserver/_matrix/media/r0/download/${serverName ?? homeserver}/$mediaId';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}

dynamic buildMediaUploadRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String fileName,
  String fileType = 'application/jpeg', // Content-Type: application/pdf
}) {
  String url = '$protocol$homeserver/_matrix/media/r0/upload';

  // Params
  url += fileName != null ? '?filename=${fileName}' : '';

  Map<String, String> headers = {
    'Content-Type': '$fileType',
    'Authorization': 'Bearer $accessToken',
  };

  return {'url': url, 'headers': headers};
}
