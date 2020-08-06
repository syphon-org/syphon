/**
 * Constants that cannot be localized
 * taken as a convention from Android
 */
class Values {
  static const appId = 'org.tether.tether';
  static const appName = 'Syphon';
  static const appNameLabel = 'syphon';
  static const appNameLong = 'Syphon Messenger';
  static const appDisplayName = 'Syphon Client';

  static const defaultLanguage = 'en-US';

  // Notifications and Background service
  static const channel_id = '${appName}_notifications';
  static const channel_id_background_service =
      '${appName}_background_notification';
  static const default_channel_title = '$appName';

  static const channel_name_messages = 'Messages';
  static const channel_name_background_service = 'Background Sync';
  static const channel_description =
      '${appName} messaging client message and status notifications';

  static const captchaUrl =
      'https://recaptcha-flutter-plugin.firebaseapp.com/?api_key=';

  static const captchaMatrixPublicKey =
      '6LcgI54UAAAAABGdGmruw6DdOocFpYVdjYBRe4zb';

  static const supportEmail = 'support@syphon.org';

  static const openHelpUrl =
      'mailto:$supportEmail?subject=Syphon%20App%20Help&body=Leave%20your%20feedback%20or%20question%20here';

  static const openSourceLibraries = [
    {"title": 'testing', 'license': 'MIT', 'version': '1.2.3'},
  ];

  static const homeserverDefault = 'matrix.org';

  // hello darkness, my old friend
  static const emailRegex =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";

  static const clientSecretMatrix = 'MDWVwN79p5xIz7bgazVXvO8aabbVD0LN';

  // Animations
  static const animationDurationDefault = 350; // millis
  static const animationDurationDefaultFast = 275;

  static const fontFamilies = [
    'Rubik',
    "Roboto",
    "Poppins",
  ];

  static const fontSizes = [
    'Small',
    'Default',
    "Large",
  ];
}
