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
const String NOTIFICATION_PROMPT_INFO =
    'Your device will prompt you to turn on notifications for tether.\n\nDo you want to turn on message notifications?';

String formatUsernameHint(String homeserver) {
  return homeserver.length != 0
      ? 'username:$homeserver'
      : 'username:matrix.org';
}
