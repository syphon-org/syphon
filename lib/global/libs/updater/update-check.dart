import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:syphon/global/https.dart';

const String CHECK_TIMESTAMP_KEY = 'CHECKED_TIMESTAMP_KEY';
const String MARKED_VERSION_KEY = 'DISMISS_VERSION_KEY';

class UpdateChecker {
  static var latestVersion;
  static final latestBuildUri = Uri.https('github.com', 'syphon-org/syphon/releases/latest');

  static markUpdated(int version) async {
    final secureStorage = FlutterSecureStorage();
    secureStorage.write(
      key: MARKED_VERSION_KEY,
      value: version.toString(),
    );
  }

  static markDismissed(int version) async {
    final secureStorage = FlutterSecureStorage();
    secureStorage.write(
      key: MARKED_VERSION_KEY,
      value: version.toString(),
    );
  }

  static markChecked() async {
    final secureStorage = FlutterSecureStorage();
    secureStorage.write(
      key: CHECK_TIMESTAMP_KEY,
      value: DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch.toString(),
    );
  }

  static checkHasUpdate() async {
    final secureStorage = FlutterSecureStorage();

    // Latest version acknowledge by the user
    final markedVersionString = await secureStorage.read(key: MARKED_VERSION_KEY);
    final markedVersion = int.parse(markedVersionString ?? '0');

    // Last timestamp when we checked for an update
    final checkTimestamp = await secureStorage.read(key: CHECK_TIMESTAMP_KEY);
    final checkDateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(checkTimestamp ?? '0'));

    // Ignore if recently checked for an update and not enough time has passed
    if (checkDateTime.isAfter(DateTime.now())) {
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = int.parse(packageInfo.version.replaceAll('.', ''));

    // Extract the build tag from the redirect
    final request = http.Request('Get', latestBuildUri)..followRedirects = false;
    final response = await httpClient.send(request);

    if (!response.headers.containsKey('location')) {
      return;
    }

    // Extract the tag
    final redirectUri = Uri.parse(response.headers['location']!);
    final remoteVersion = int.parse(redirectUri.pathSegments.last.replaceAll('.', ''));

    // Mark that we've checked for the latest version
    await markChecked();

    // Ignore if user has already dismissed this update
    if (remoteVersion <= markedVersion) {
      return false;
    }

    latestVersion = remoteVersion;

    return remoteVersion > currentVersion;
  }
}
