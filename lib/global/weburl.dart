import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

Future<void> launchUrlWrapper(String url, {bool forceSafariVC = false}) async {
  final uri = Uri.parse(url);
  final isLaunchable = await canLaunchUrl(uri);

  if (!Platform.isAndroid && !isLaunchable) {
    throw 'Could not launch $url';
  }

  await launchUrl(
    uri,
    mode: !forceSafariVC ? LaunchMode.externalApplication : LaunchMode.platformDefault,
  );
}
