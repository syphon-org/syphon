const String SELECT_USERNAME_TITLE = 'Select your usernames homeserver';

String formatUsernameHint(String homeserver) {
  return homeserver.length != 0
      ? 'username:$homeserver'
      : 'username:matrix.org';
}

class StringStore {
  static const app_name = 'Tether';
  static const app_name_long = 'Tether Messenger';
  static const app_id = 'org.tether.tether';
  static const default_language = 'en-US';

  static const titleIntro = 'Welcome to Tether';
  static const titleLogin = 'take back the chat';

  static const subtitleIntro = 'Privacy and freedom\nwithout the hassle';

  static const contentIntroOne =
      'Tether works by using an encrypted \nand decentralized protocol \ncalled ';

  static const buttonLogin = 'login';
  static const buttonTextLogin = 'Login';

  static const start_chat_notice = 'Even if you don\'t send a message, ' +
      'the user will still see your invite to chat.';

  static const confirmation_alpha_version_notice =
      'Thanks for trying out Tether!\n\nPlease be aware this app is still very much in Alpha.\n\n' +
          'With that said, please read the below terms and conditions for this application and if you agree select "I Agree" to continue:\n\n';

  static const confirmation_tether_terms_of_service =
      'THIS SOFTWARE IS PROVIDED BY THE AUTHOR \'\'AS IS\'\' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.';

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

  static const buttonSaveGeneric = 'save';

  static const buttonIntroExistQuestion = 'Already have a username?';
  static const buttonIntroExistAction = 'Login';

  static const buttonLoginCreateQuestion = 'Don\'t have a username?';
  static const buttonLoginCreateAction = 'Create One';

  static const buttonSignupNext = 'continue';
  static const buttonSignupFinish = 'finish';

  static const encryptedMessageLabel = '[Encrypted Message Content]';

  static const semanticsLabelImageIntro = 'Relaxed, Lounging User';
}
