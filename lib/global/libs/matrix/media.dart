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
  url += accessToken != null ? '?access_token=${accessToken}' : '';

  return {'url': url};
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

  // Params
  url += accessToken != null ? '?access_token=${accessToken}' : '';

  return {'url': url};
}

dynamic buildMediaUploadRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String fileName,
  String fileType, // Content-Type: application/pdf
}) {
  String url = '$protocol$homeserver/_matrix/media/r0/upload';
  String headers;

  // Params
  url += '?access_token=${accessToken}';
  url += fileName != null ? '&filename=${fileName}' : '';

  // Headers
  headers = fileType != null ? 'Content-Type: ${fileType}' : null;

  return {'url': url, 'headers': headers};
}
