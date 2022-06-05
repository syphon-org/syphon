import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

Future<void> launchUrl(String url, {bool forceSafariVC = false}) async {
  if (!Platform.isAndroid && !(await canLaunch(url))) {
    throw 'Could not launch $url';
  }

  await launch(
    url,
    forceSafariVC: forceSafariVC,
  );
}
