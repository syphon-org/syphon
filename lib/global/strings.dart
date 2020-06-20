import 'package:Tether/global/values.dart';

class Strings {
  // Titles
  static const titleIntro = 'Welcome to ${Values.appName}';
  static const titleLogin = 'take back the chat';
  static const titleDeleteDevices = 'Confirm Removing Devices';

  // View Titles
  static const titleViewSignup = 'Signup';
  static const titleViewDevices = 'Devices';
  static const titleViewSettings = 'Settings';

  // Subtitles
  static const subtitleIntro = 'Privacy and freedom\nwithout the hassle';

  // Content
  static const contentDeleteDevices =
      'You will have to sign in again on these devices if you remove them.';

  static const contentDeleteDeviceKeyWarning =
      "Are you sure you want to export this devices encryption key? It may make it available to others if you're not careful!";
  static const contentEncryptedMessage = '[Encrypted Message Content]';

  // intro
  static const contentIntroFirstPartOne =
      '${Values.appName} works by using an encrypted \nand decentralized protocol \ncalled ';

  static const contentIntroSecondPartOne =
      'Matrix enables you to message others';

  static const contentIntroSecondPartTwo =
      'and control where the\nmessages are ';

  static const contentIntroThird =
      'Both Matrix and ${Values.appName} are developed\nopenly by organizations and people,\nnot corporations';

  static const contentIntroFinal =
      'By using ${Values.appName} and other Matrix clients\nwe can make private messaging \naccessible to everyone';

  static const contentNotificationBackgroundService =
      'Background connection enabled';
  // Buttons
  static const buttonLogin = 'login';
  static const buttonTextLogin = 'Login';
  static const buttonSaveGeneric = 'save';

  static const buttonIntroExistQuestion = 'Already have a username?';
  static const buttonIntroExistAction = 'Login';

  static const buttonLoginCreateQuestion = 'Don\'t have a username?';
  static const buttonLoginCreateAction = 'Create One';

  static const buttonSignupNext = 'continue';
  static const buttonSignupFinish = 'finish';
  static const buttonLetsChat = 'let\'s chat';
  static const buttonCancel = 'cancel';

  // Confirmations
  static const confirmationStartChat = 'Even if you don\'t send a message, ' +
      'the user will still see your invite to chat.';
  static const confirmationAttemptChat = 'Even if you don\'t send a message, ' +
      'the user will still see your invite to chat if they exist.\n\nDo you want to try chatting with this username?';
  static const confirmationAppTermsOfService =
      'THIS SOFTWARE (${Values.appName}) IS PROVIDED BY THE AUTHOR \'\'AS IS\'\' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.';
  static const confirmationNotifications =
      'Your device will prompt you to turn on notifications for ${Values.appName}.\n\nDo you want to turn on message notifications?';
  static const confirmationInteractiveAuth =
      'In order to perform this action, you\'ll need to enter your password again';
  static const confirmationAlphaVersion =
      'Thanks for trying out ${Values.appName}!\n\nPlease be aware this app is still very much in Alpha.\n\n' +
          'With that said, please read the below terms and conditions for this application and if you agree select "I Agree" to continue:\n\n';
  static const confirmationAcceptInvite =
      'If you accept this room invite, the users in the room will be made aware you\'ve accepted. Are you sure you want to accept now?';

  static const confirmationEncryption =
      'After you encrypt a chat, you cannot go back to sending messages unencrypted. Are you sure you want to encrypt this chat?';

  // Placeholders
  static const placeholderInputMatrixUnencrypted =
      'Matrix message (unencrypted)';

  static const placeholderInputMatrixEncrypted = 'Matrix message';

  static String formatUsernameHint(String homeserver) {
    return homeserver.length != 0
        ? 'username:$homeserver'
        : 'username:matrix.org';
  }

  // Tooltips
  static const tooltipSelectHomeserver = 'Select your usernames homeserver';

  // Accessibility
  static const semanticsIntroFinal =
      'Two people different feeling confident and lookin\' good';
  static const semanticsLabelImageIntro = 'Relaxed, Lounging User';
}
