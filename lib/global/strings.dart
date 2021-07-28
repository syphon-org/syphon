import 'package:easy_localization/easy_localization.dart';
import 'package:syphon/global/string-keys.dart';
import 'package:syphon/global/values.dart';

///
/// Strings
///
/// Hides library used for i18n / localization and
/// gives static references to all strings used in the app
///
class Strings {
  // Titles
  static final titleIntro = tr('title-intro', args: [Values.appName]);
  static final titleProfile = tr('title-view-profile');
  static final titleTheming = tr('title-view-theming');
  static final titleDevices = tr(StringKeys.titleDevices);
  static final titlePrivacy = tr(StringKeys.titlePrivacy);
  static final titleSettings = tr('title-view-settings');
  static final titleAdvanced = tr('title-view-advanced');
  static final titleInvite = tr('title-view-invite');
  static final titleChatUsers = tr('title-view-chat-users');
  static final titleConfirmEmail = tr('title-confirm-email');
  static final titleChatSettings = tr(StringKeys.titleChatSettings);
  static final titleSearchGroups = tr('title-view-search-groups');
  static final titleSearchUsers = tr('title-view-search-users');
  static final titleInviteUsers = tr('title-view-invite');
  static final titleCreateGroup = tr('title-view-create-group');
  static final titleCreateGroupPublic = tr('title-view-create-group-public');
  static final titleEmailRequirement = tr('title-dialog-email-requirement');
  static final titleConfirmPassword = tr(StringKeys.titleConfirmPassword);
  static final titleConfirmDeleteKeys = tr(StringKeys.titleConfirmDeleteKeys);
  static final titleHomeserverSearch = tr(StringKeys.titleHomeserverSearch);

  // Titles (Dialogs)
  static final titleDialogEncryption = tr(StringKeys.titleDialogEncryption);
  static final titleDialogTerms = tr(StringKeys.titleDialogTerms);
  static final titleDialogTermsAlpha = tr(StringKeys.titleDialogTermsAlpha);
  static final titleDialogCaptcha = tr(StringKeys.titleDialogCaptcha);
  static final titleDialogSignupEmailVerification = tr(StringKeys.titleDialogSignupEmailVerification);
  static final titleDialogEmailRequirement = tr('title-dialog-email-requirement');

  // Headers
  static final headerIntro = tr('header-intro');
  static final headerLogin = tr('header-login');

  // Labels
  static final labelUsers = tr(StringKeys.labelUsers);
  static final labelEmail = tr(StringKeys.labelEmail);
  static final labelSyncing = tr(StringKeys.labelSyncing);
  static final labelSearchUser = tr(StringKeys.labelSearchUser);
  static final labelUsersRecent = tr(StringKeys.labelUsersRecent);
  static final labelSearching = tr(StringKeys.labelSearching);
  static final labelKnownUsers = tr(StringKeys.labelKnownUsers);
  static final labelGroupsEmpty = tr(StringKeys.labelGroupsEmpty);
  static final labelUsersResults = tr(StringKeys.labelUsersResults);
  static final labelMessagesEmpty = tr(StringKeys.labelMessagesEmpty);
  static final labelSearchHomeservers = tr(StringKeys.labelSearchHomeservers);
  static final labelSearchResults = tr('label-search-results'); // 'Search Results'
  static final labelRoomNameDefault = tr('label-chat-default'); // 'New Chat'
  static final labelNoMessages = tr('label-messages-empty'); // 'no messages found';
  static final labelNoGroups = tr('label-groups-empty'); // 'no groups found';
  static final labelEncryptedMessage = tr('label-message-encrypted'); //  'Encrypted Message';
  static final labelDeletedMessage = tr('label-message-deleted'); // 'This message was deleted';
  static final labelOn = tr('label-on'); // 'On';
  static final labelOff = tr('label-off'); // 'Off';
  static final labelTermsOfService = tr('label-terms-of-service');

  // List Items
  static final listItemSettingsSms = tr(StringKeys.listItemSettingsSms);
  static final listItemSettingsChat = tr(StringKeys.listItemSettingsChat);
  static final listItemSettingsNotification = tr(StringKeys.listItemSettingsNotification);
  static final listItemSettingsPrivacy = tr(StringKeys.listItemSettingsPrivacy);
  static final listItemSettingsLogout = tr(StringKeys.listItemSettingsLogout);

  // Buttons
  static final buttonLogin = tr(StringKeys.buttonLogin);
  static final buttonNext = tr(StringKeys.buttonNext);
  static final buttonFinish = tr(StringKeys.buttonFinish);
  static final buttonLoginSSO = tr(StringKeys.buttonLoginSSO);
  static final buttonSaveGeneric = tr('button-save-generic'); // 'save';
  static final buttonSendVerification = tr('button-send-verification'); // 'send verification email';
  static final buttonConfirmVerification = tr('button-confirm-verification'); //  'confirm verification';
  static final buttonStartChat = tr('button-start-chat'); // 'let\'s chat';
  static final buttonCreate = tr('button-create'); // 'create';
  static final buttonCancel = tr('button-cancel'); //'cancel';
  static final buttonEnable = tr('button-enable'); //'enable';
  static final buttonDeactivate = tr('button-deactivate'); //  'deactivate';
  static final buttonQuit = tr('button-quit'); //  'quit';
  static final buttonConfirm = tr('button-confirm'); //  'got it';
  static final buttonConfirmFormal = tr('button-confirm-formal'); // 'confirm';
  static final buttonConfirmAlt = tr('button-confirm-alt'); //  'ok';
  static final buttonBlocKUser = tr('button-block-user'); //  'block user';
  static final buttonDeleteKeys = tr('button-delete-key'); //  'delete keys';
  static final buttonResetPassword = tr('button-reset-password'); // 'reset password';

  // Buttons (Text)
  static final buttonTextSignupQuestion = tr(StringKeys.buttonTextSignupQuestion);
  static final buttonTextSignupAction = tr(StringKeys.buttonTextSignupAction);
  static final buttonTextAgreement = tr('button-text-agreement'); // 'I Agree';
  static final buttonTextSeeAllUsers = tr('button-text-see-all-users'); // ; 'See All Users';
  static final buttonTextExistingUser = tr('button-text-existing-user'); // 'Already have a username?';
  static final buttonTextExistingAction = tr('button-text-login'); // 'Login';
  static final buttonTextLogin = tr('button-text-login'); // 'Login';
  static final buttonTextLoadCaptcha = tr('button-text-load-captcha');
  static final buttonTextConfirmed = tr('button-text-confirmed');

  // Placeholders
  static final placeholderTopic = tr('placeholder-topic');
  static final placeholderMatrixUnencrypted = tr('label-message-matrix-unencrypted');
  static final placeholderMatrixEncrypted = tr('label-message-matrix');

  // Warnings
  static final warningDeactivateAccount = tr('warning-deactivate-account');
  static final warrningDeactivateAccountFinal = tr('warning-deactivate-account-final');

  // Alerts
  static final alertAppRestartEffect = tr(StringKeys.alertAppRestartEffect);
  static final alertInviteUnknownUser = tr('alert-invite-user-unknown');
  static final alertMessageSendingFailed = tr('alert-message-failed'); // 'Message Failed To Send';
  static final alertCheckHomeserver = tr('alert-homeserver-invalid'); // 'Message Failed To Send';
  static final alertFeatureInProgress = tr(StringKeys.alertFeatureInProgress);

  // Alert (Non-Flutter / Background Thread)
  static const alertBackgroundService = 'Background connection enabled';

  // Content
  static final contentPasswordRecommendation = tr('content-password-recommendation');
  static final contentDeleteDevices = tr('content-dialog-devices-delete');
  static final contentConfirmDeleteKeys = tr(StringKeys.contentConfirmDeleteKeys);
  static final contentKeyExportWarning = tr('content-dialog-devices-key-export');
  static final contentEmailRequirement = tr('content-signup-email-requirement');
  static final contentForgotEmailVerification = tr('content-forgot-email-verification');
  static final contentConfirmPasswordReset = tr('content-confirm-password-reset');
  static final contentPasswordRequirements = tr('content-password-requirements');
  static final contentEmailVerifiedRequirement = tr('content-signup-email-verification');
  static final contentSignupEmailVerification = tr(StringKeys.contentSignupEmailVerification);
  static final contentCaptchaRequirement = tr('content-signup-captcha-requirement');

  static final contentIntroFirstPartOne = tr('content-intro-section-one', args: [Values.appName]);
  static final contentIntroSecondPartOne = tr('content-intro-section-two');
  static final contentIntroSecondPartBold = tr('content-intro-section-two-part-two');
  static final contentIntroSecondPartTwo = tr('content-intro-section-two-part-three');
  static final contentIntroThird = tr('content-intro-section-three', args: [Values.appName]);
  static final contentIntroFinal = tr('content-intro-section-four', args: [Values.appName]);

  // Confirmations
  static final confirmInvite = tr('confirm-invite');
  static final confirmInvites = tr('confirm-invite-multiple');
  static final confirmStartChat = tr('confirm-start-chat');
  static final confirmDeactivate = tr('prompt-confirm-deactivate');
  static final confirmAttemptChat = tr('confirm-attempt-chat');
  static final confirmAdvancedColors = tr('confirm-advanced-colors');
  static final confirmAppTermsOfService = tr('confirm-terms-of-service', args: [Values.appName]);
  static final confirmnEnableNotifications = tr('confirm-enable-notifications', args: [Values.appName]);
  static final confirmationThanks = tr('content-thanks', args: [Values.appName]);
  static final confirmAuthVerification = tr('confirm-auth-verification');
  static final confirmAcceptInvite = tr('confirm-chat-invite');
  static final confirmEncryption = tr('confirm-encryption');
  static final confirmGroupEncryption = tr('confirm-encryption-group');
  static final confirmModifySyncInterval = tr('content-sync-interval');

  static final confirmationAlphaVersion = tr('confirm-alpha-version');
  static final confirmationAlphaWarning = tr('confirm-alpha-warning');
  static final confirmationAlphaWarningAlt = tr('confirm-alpha-warning-alt');
  static final confirmationConclusion = tr('confirm-terms-of-service-alt');

  // Accessibility
  static final semanticsImageIntro = tr('semnatics-image-intro');
  static final semanticsPrivateMessage = tr('semnatics-image-private-message');
  static final semanticsSendArrow = tr('semnatics-image-send-arrow');
  static final semanticsIntroFinal = tr('semnatics-image-intro-section-four');
  static final semanticsIntroThird = tr('semnatics-image-intro-section-third');
  static final semanticsHomeDefault = tr('semantics-image-empty-chat-list');
}
