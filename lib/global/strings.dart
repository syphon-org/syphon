const String LOGIN_TITLE = 'take back the chat';
const String LOGIN_BUTTON_TEXT = 'login';
const String LOGIN_TEXT_BUTTON_TEXT = 'Login';

const String CREATE_USER_TEXT = 'Don\'t have a username?';
const String CREATE_USER_TEXT_ACTION = 'Create one';

const String SELECT_USERNAME_TITLE = 'Select your usernames homeserver';

const String INTRO_LOGIN_TEXT = 'Already have a username?';
const String INTRO_LOGIN_ACTION = 'Login';

const String INTRO_IMAGE_LABEL = 'Relaxed, Lounging User';
const String INTRO_TITLE = 'Welcome to Tether';
const String INTRO_SUBTITLE =
    'Take back your privacy and freedom\nwithout the hassle';

String formatUsernameHint(String homeserver) {
  return homeserver.length != 0
      ? 'username:$homeserver'
      : 'username:matrix.org';
}

class StringStore {
  static const app_name = 'Tether';
  static const start_chat_notice = 'Even if you don\'t send a message, ' +
      'the user will still see your invite to chat.';
  static const notificationConfirmation =
      'Your device will prompt you to turn on notifications for tether.\n\nDo you want to turn on message notifications?';

  static const interactiveAuthConfirmation =
      'In order to perform this action, you\'ll need to enter your password again';

  static const deleteDevicesTitle = 'Confirm Removing Devices';
  static const deleteDevicesConfirmation =
      'You will have to sign in again on these devices if you remove them.';

  static const viewTitleSignup = 'Signup';
  static const viewTitleDevices = 'Devices';
  static const viewTitleSettings = 'Settings';
}
