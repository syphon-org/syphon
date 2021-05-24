import 'package:flutter/foundation.dart';

/// Constants that cannot be localized
/// taken as a convention from Android
class Values {
  static const appId = 'org.tether.tether';
  static const appName = 'Syphon';
  static const appNameLabel = 'syphon';
  static const appNameLong = 'Syphon Messenger';
  static const appDisplayName = 'Syphon';

  static const defaultLanguage = 'en-US';

  // Notifications and Background service
  static const channel_id = '${appNameLabel}_notifications';
  static const channel_id_background_service =
      '${appName}_background_notification';
  static const default_channel_title = appName;

  static const channel_group_key = 'org.tether.tether.MESSAGES';
  static const channel_name_messages = 'Messages';
  static const channel_name_background_service = 'Background Sync';
  static const channel_description =
      '$appName messaging client message and status notifications';

  static const captchaUrl =
      'https://recaptcha-flutter-plugin.firebaseapp.com/?api_key=';

  static const captchaMatrixPublicKey =
      '6LcgI54UAAAAABGdGmruw6DdOocFpYVdjYBRe4zb';

  static const supportEmail = 'hello@syphon.org';

  static const matrixSSOUrl =
      '/_matrix/client/r0/login/sso/redirect?redirectUrl=syphon://syphon.org/login/token';

  static const openHelpUrl =
      'mailto:$supportEmail?subject=Syphon%20Support%20-%20App&body=Hey%20Syphon%20Team%2C%0D%0A%0D%0A%3CLeave%20your%20feedback%2C%20questions%20or%20concerns%20here%3E%0D%0A%0D%0AThanks!';

  static const openSourceLibraries = [
    {'title': 'testing', 'license': 'MIT', 'version': '1.2.3'},
  ];

  static const homeserverDefault = 'matrix.org';

  // hello darkness, my old friend
  static const emailRegex =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";

  static const urlRegex =
      r'[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)';

  static const clientSecretMatrix = 'MDWVwN79p5xIz7bgazVXvO8aabbVD0LN';

  static const redacted = 'redacted';

  // Animations
  static const animationDurationDefault = 350; // millis
  static const animationDurationDefaultFast = 275;
  static const serviceNotificationTimeoutDuration = 65000; // millis

  static const defaultHeaders = {'Content-type': 'application/json'};
  static const fontFamilies = [
    'Rubik',
    'Roboto',
    'Poppins',
    'Inter',
  ];

  static const fontSizes = [
    'Small',
    'Default',
    'Large',
  ];

  static const messageSizes = [
    'Small',
    'Default',
    'Large',
  ];
}

// ignore: non_constant_identifier_names
final bool DEBUG_MODE = !kReleaseMode;
