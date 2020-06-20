/**
 * Constants that cannot be localized
 * taken as a convention from Android
 */
class Values {
  static const appId = 'org.tether.tether';
  static const appName = 'Syphon';
  static const appNameLabel = 'tether'; // TODO: change to syphon
  static const appNameLong = 'Syphon Messenger';

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
}
