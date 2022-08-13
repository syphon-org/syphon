import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:syphon/global/https.dart';
import 'package:syphon/store/hooks.dart';
import 'package:syphon/store/index.dart';

class UpdateChecker {
  static DateTime? lastChecked;
  static DateTime nextCheckNotBefore = DateTime.utc(1970);
  static bool updateAvailable = false;

  static final latestBuildUri =
      Uri.https('github.com', 'syphon-org/syphon/releases/latest');

  static checkForUpdate() async {
    final enabled = useSelector<AppState, bool>(
            (state) => state.settingsStore.checkForUpdatesEnabled) ??
        false;

    if (!enabled ||
        nextCheckNotBefore.isAfter(DateTime.now()) ||
        updateAvailable) {
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = int.parse(packageInfo.version.replaceAll('.', ''));

    //Extract the build tag from the redirect
    final request = http.Request('Get', latestBuildUri)
      ..followRedirects = false;

    //Make sure to send over our client to respect the proxy
    final response = await httpClient.send(request);

    if (!response.headers.containsKey('location')) {
      return;
    }

    final redirectUri = Uri.parse(response.headers['location']!);
    final version = int.parse(redirectUri.pathSegments.last //extract the tag
        .replaceAll('.', ''));

    lastChecked = DateTime.now();

    if (version > currentVersion) {
      updateAvailable = true;
    }

    nextCheckNotBefore = lastChecked!.add(Duration(hours: 18));
  }
}
