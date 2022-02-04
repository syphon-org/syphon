import 'package:easy_localization/easy_localization.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/rooms/room/model.dart';

extension Capitalize on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

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
  static final titleDevices = tr('title-view-devices');
  static final titlePrivacy = tr('title-view-privacy');
  static final titleSettings = tr('title-view-settings');
  static final titleAdvanced = tr('title-view-advanced');
  static final titleVerification = tr('title-verification');
  static final titleInvite = tr('title-view-invite');
  static final titleChatUsers = tr('title-view-chat-users');
  static final titleChatSettings = tr('title-view-settings-chat');
  static final titleSearchGroups = tr('title-view-search-groups');
  static final titleSearchUsers = tr('title-view-search-users');
  static final titleInviteUsers = tr('title-view-invite-users');
  static final titleCreateGroup = tr('title-view-create-group');
  static final titleCreateGroupPublic = tr('title-view-create-group-public');
  static final titleEmailRequirement = tr('title-dialog-email-requirement');
  static final titleHomeserverSearch = tr('title-view-homeserver-search');
  static final titleProxySettings = tr('title-proxy-settings');
  static final titleUseProxyServer = tr('title-proxy-use-proxy');
  static final titleProxyHost = tr('title-proxy-host');
  static final titleProxyPort = tr('title-proxy-port');
  static final titleProxyUseBasicAuthentication = tr('title-proxy-use-basic-authentication');
  static final titleProxyUsername = tr('title-proxy-username');
  static final titleProxyPassword = tr('title-proxy-password');
  static final titleLockOverlay = tr('title-lock-overlay');
  static final titleConfirmLockOverlay = tr('title-confirm-lock-overlay');
  static final titleSearchUnencrypted = tr('title-search-unencrypted');
  static final titleMessageDetails = tr('title-message-details');
  static final titleSendMediaMessage = tr('title-send-media-message');
  static final titleSendMediaMessageUnencrypted = tr('title-send-media-message-unencrypted');
  static final titleToggleAutocorrect = tr('title-toggle-autocorrect');
  static final titleToggleSuggestions = tr('title-toggle-suggestions');


  // Titles (Dialogs)
  static final titleDialogConfirmLinkout = tr('title-dialog-confirm-linkout');
  static final titleDialogEncryption = tr('title-dialog-encryption');
  static final titleDialogTerms = tr('title-dialog-terms');
  static final titleDialogTermsAlpha = tr('title-dialog-terms-alpha');
  static final titleDialogCaptcha = tr('title-dialog-captcha');
  static final titleDialogSignupEmailVerification = tr('title-dialog-email-requirement-verified');
  static final titleConfirmPassword = tr('title-confirm-password');
  static final titleRenameDevice = tr('title-device-rename');
  static final titleConfirmDeleteKeys = tr('title-dialog-delete-keys');
  static final titleConfirmEmail = tr('title-confirm-email');
  static final titleDialogColorPicker = tr('title-dialog-color-picker');
  static final titleDialogAcceptInvite = tr('title-dialog-accept-invite');
  static final titleDialogChatColor = tr('title-dialog-chat-color');
  static final titleDialogDraftPreview = tr('title-dialog-draft-preview');

  // Subtitles
  static final subtitleUseProxyServer = tr('subtitle-proxy-use-proxy');
  static final subtitleProxyUseBasicAuthentication = tr('subtitle-proxy-use-basic-authentication');
  static final subtitleSettingsSyncInterval = tr('subtitle-settings-sync-interval');
  static final subtitleSettingsSyncToggle = tr('subtitle-settings-sync-toggle');
  static final subtitleToggleAutocorrect = tr('subtitle-toggle-autocorrect');
  static final subtitleToggleSuggestions = tr('subtitle-toggle-suggestions');

  // Headers
  static final headerIntro = tr('header-intro');
  static final headerLogin = tr('header-login');
  static final headerSignupUsername = tr('header-signup-username');

  // Labels
  static final labelBack = tr('label-back');
  static final labelSend = tr('label-send');
  static final labelUsers = tr('label-users');
  static final labelEmail = tr('label-email');
  static final labelClose = tr('label-close');
  static final labelSyncing = tr('label-syncing');
  static final labelSearchUser = tr('label-search-user');
  static final labelUsersRecent = tr('label-users-recent');
  static final labelSearching = tr('label-searching');
  static final labelKnownUsers = tr('label-users-known');
  static final labelGroupsEmpty = tr('label-groups-empty');
  static final labelUsersResults = tr('label-users-results');
  static final labelCallInvite = tr('label-call-invite');
  static final labelCallHangup = tr('label-call-hangup');
  static final labelMessagesEmpty = tr('label-messages-empty');
  static final labelSendEncrypted = tr('label-send-encrypted');
  static final labelDownloadImage = tr('label-download-image');
  static final labelSendUnencrypted = tr('label-send-unencrypted');
  static final labelSearchHomeservers = tr('label-search-homeservers');
  static final labelSearchResults = tr('label-search-results'); // 'Search Results'
  static final labelRoomNameDefault = tr('label-chat-default'); // 'New Chat'
  static final labelEncryptedMessage = tr('label-message-encrypted'); //  'Encrypted Message';
  static final labelDeletedMessage = tr('label-deleted-message'); // 'This message was deleted';
  static final labelOn = tr('label-on'); // 'On';
  static final labelOff = tr('label-off'); // 'Off';
  static final labelTermsOfService = tr('label-terms-of-service');
  static final labelSearchUnencrypted = tr('label-search-unencrypted');
  static final labelAbout = tr('label-about');
  static final labelChatSettings = tr('label-chat-settings');
  static final labelColor = tr('label-color');

  // List Items
  static final listItemSettingsSms = tr('list-item-settings-sms');
  static final listItemSettingsNotification = tr('list-item-settings-notification');
  static final listItemSettingsPrivacy = tr('list-item-settings-privacy');
  static final listItemSettingsLogout = tr('list-item-settings-logout');
  static final listItemSettingsProxy = tr('list-item-settings-proxy');
  static final listItemSettingsProxyHost = tr('list-item-settings-proxy-host');
  static final listItemSettingsProxyPort = tr('list-item-settings-proxy-port');
  static final listItemSettingsProxyUsername = tr('list-item-settings-proxy-username');
  static final listItemSettingsProxyPassword = tr('list-item-settings-proxy-password');
  static final listItemSettingsSyncInterval = tr('list-item-settings-sync-interval');
  static final listItemSettingsSyncToggle = tr('list-item-settings-sync-toggle');

  static String listItemUserDetailsStartChat(String? name) =>
      tr('list-item-user-details-start-chat', args: ['$name']);
  static final listItemUserDetailsRoomInvite = tr('list-item-user-details-room-invite');
  static final listItemUserDetailsSendMessage = tr('list-item-user-details-send-message');
  static final listItemUserDetailsViewProfile = tr('list-item-user-details-view-profile');
  static final listItemUserDetailsUnblockUser = tr('list-item-user-details-unblock-user');
  static final listItemUserDetailsBlockUser = tr('list-item-user-details-block-user');

  static final listItemImageOptionsPhotoSelectMethod =
      tr('list-item-image-options-photo-select-method');
  static final listItemImageOptionsTakePhoto = tr('list-item-image-options-take-photo');
  static final listItemImageOptionsPickFromGallery =
      tr('list-item-image-options-pick-from-gallery');
  static final listItemImageOptionsRemovePhoto = tr('list-item-image-options-remove-photo');

  static String listItemContextSwitcherUserDisplayName(String? username) =>
      tr('list-item-context-switcher-user-display-name', args: ['$username']);
  static final listItemContextSwitcherAccounts = tr('list-item-context-switcher-accounts');
  static final listItemContextSwitcherAddAccount = tr('list-item-context-switcher-add-account');

  static final listItemAdvancedSettingsLicenses = tr('list-item-advanced-settings-licenses');
  static final listItemAdvancedSettingsStartBackground =
      tr('list-item-advanced-settings-start-background');
  static final listItemAdvancedSettingsStopBackground =
      tr('list-item-advanced-settings-stop-background');
  static final listItemAdvancedSettingsTestNotifications =
      tr('list-item-advanced-settings-test-notifications');
  static final listItemAdvancedSettingsTestSyncLoop =
      tr('list-item-advanced-settings-test-sync-loop');
  static final listItemAdvancedSettingsForceFunction =
      tr('list-item-advanced-settings-force-function');

  static final listItemSent = tr('list-item-sent');
  static final listItemReceived = tr('list-item-received');
  static final listItemVia = tr('list-item-via');
  static final listItemFrom = tr('list-item-from');
  static final listItemReadBy = tr('list-item-read-by');

  static final listItemChatDetailToggleDirectChat = tr('list-item-chat-detail-toggle-direct-chat');
  static final listItemChatDetailNotificationSetting =
      tr('list-item-chat-detail-notification-setting');
  static final listItemChatDetailNotifications = tr('list-item-chat-detail-notifications');
  static final listItemChatDetailVibrate = tr('list-item-chat-detail-vibrate');
  static final listItemChatDetailNotificationSound = tr('list-item-chat-detail-notification-sound');
  static final listItemChatDetailPrivacyStatus = tr('list-item-chat-detail-privacy-status');
  static final listItemChatDetailViewKey = tr('list-item-chat-detail-view-key');

  // Buttons
  static final buttonLogin = tr('button-login');
  static final buttonNext = tr('button-next');
  static final buttonFinish = tr('button-finish');
  static final buttonLoginSSO = tr('button-login-sso');
  static final buttonSave = tr('button-save');
  static final buttonSendVerification = tr('button-send-verification');
  static final buttonConfirmVerification = tr('button-confirm-verification');
  static final buttonStartChat = tr('button-start-chat'); // 'let\'s chat';
  static final buttonCreate = tr('button-create'); // 'create';
  static final buttonCancel = tr('button-cancel'); //'cancel';
  static final buttonEnable = tr('button-enable'); //'enable';
  static final buttonDeactivate = tr('button-deactivate'); //  'deactivate';
  static final buttonQuit = tr('button-quit'); //  'quit';
  static final buttonConfirm = tr('button-confirm'); //  'got it';
  static final buttonConfirmFormal = tr('button-confirm-formal'); // 'confirm';
  static final buttonConfirmAlt = tr('button-confirm-alt'); //  'ok';
  static final buttonBlockUser = tr('button-block-user'); //  'block user';
  static final buttonLeaveChat = tr('button-leave-chat'); // 'leave chat';
  static final buttonDeleteChat = tr('button-delete-chat');
  static final buttonArchiveChat = tr('button-archive-chat');
  static final buttonSelectAll = tr('button-select-all');
  static final buttonRoomDetails = tr('button-chat-details');
  static final buttonResetPassword = tr('button-reset-password'); // 'reset password';
  static final buttonDismiss = tr('button-dismiss');
  static final buttonSaveMessageEdit = tr('button-save-message-edit');

  // Buttons (Text)
  static final buttonTextLogin = tr('button-text-login'); // 'Login';
  static final buttonTextLoginQuestion = tr('button-text-login-question');
  static final buttonTextSignupAction = tr('button-text-signup-action');
  static final buttonTextSignupQuestion = tr('button-text-signup-question');
  static final buttonTextAgreement = tr('button-text-agreement'); // 'I Agree';
  static final buttonTextSeeAllUsers = tr('button-text-see-users'); // ; 'See All Users';
  static final buttonTextLoadCaptcha = tr('button-text-load-captcha');
  static final buttonTextConfirmed = tr('button-text-confirmed');
  static final buttonTextDeleteKeys = tr('button-delete-keys'); //  'delete keys';
  static final buttonTextLetsEncrypt = tr('button-text-lets-encrypt');
  static final buttonTextGoBack = tr('button-text-go-back');
  static final buttonTextReject = tr('button-text-reject');
  static final buttonTextAccept = tr('button-text-accept');

  // Buttons (Options)
  static final buttonTextCreateGroup = tr('button-text-create-group');
  static final buttonTextMarkAllRead = tr('button-text-mark-all-read');
  static final buttonTextInvite = tr('button-text-invite');
  static final buttonTextSettings = tr('button-text-settings');
  static final buttonTextSupport = tr('button-text-support');

  // Buttons (Media Cards)
  static final buttonGallery = tr('button-gallery');
  static final buttonFile = tr('button-file');
  static final buttonContact = tr('button-contact');
  static final buttonLocation = tr('button-location');

  // Placeholders
  static final placeholderTopic = tr('placeholder-topic');
  static final placeholderMatrixEncrypted = tr('label-message-matrix');
  static final placeholderMatrixUnencrypted = tr('label-message-matrix-unencrypted');
  static final placeholderDefaultRoomNotification = tr('label-default-room-notification');

  // Warnings
  static final warningDeactivateAccount = tr('warning-deactivate-account');
  static final warrningDeactivateAccountFinal = tr('warning-deactivate-account-final');

  // Alerts
  static final alertAppRestartEffect = tr('alert-restart-app-effect');
  static final alertInviteUnknownUser = tr('alert-invite-user-unknown');
  static final alertMessageSendingFailed = tr('alert-message-failed'); // 'Message Failed To Send';
  static final alertCheckHomeserver = tr('alert-homeserver-invalid'); // 'Message Failed To Send';
  static final alertFeatureInProgress = tr('alert-feature-in-progress');
  static final alertHiddenReadReceipts = tr('alert-hidden-read-receipts');
  static final alertOffline = tr('alert-offline');
  static final alertUnknown = tr('alert-unknown');
  static String alertCouldNotLaunchURL(String? url) =>
      tr('alert-could-not-launch-url', args: ['$url']);
  static final alertNoImagesFound = tr('alert-no-images-found');

  // Alert (Non-Flutter / Background Thread w/o i18n)
  static const alertBackgroundService = 'Background connection enabled';

  // Content
  static final contentCaptchaWarning = tr('content-captcha-warning');
  static final contentPasswordRecommendation = tr('content-password-recommendation');
  static final contentDeleteDevices = tr('content-dialog-devices-delete');
  static final contentRenameDevice = tr('content-dialog-device-rename');
  static final contentKeyExportWarning = tr('content-dialog-devices-key-export');
  static final contentEmailRequirement = tr('content-signup-email-requirement');
  static final contentEmailVerification = tr('content-signup-email-verification');
  static final contentForgotEmailVerification = tr('content-forgot-email-verification');
  static final contentConfirmPasswordReset = tr('content-confirm-password-reset');
  static final contentPasswordRequirements = tr('content-password-requirements');
  static final contentCaptchaRequirement = tr('content-signup-captcha-requirement');

  static final contentIntroFirstPartOne = tr('content-intro-section-one', args: [Values.appName]);
  static final contentIntroSecondPartOne = tr('content-intro-section-two');
  static final contentIntroSecondPartBold = tr('content-intro-section-two-part-two');
  static final contentIntroSecondPartTwo = tr('content-intro-section-two-part-three');
  static final contentIntroThird = tr('content-intro-section-three', args: [Values.appName]);
  static final contentIntroFinal = tr('content-intro-section-four', args: [Values.appName]);

  static final contentProxyHost = tr('content-proxy-host');
  static final contentProxyPort = tr('content-proxy-port');
  static final contentProxyUsername = tr('content-proxy-username');
  static final contentProxyPassword = tr('content-proxy-password');

  static final contentNotificationStyleTypeInbox = tr('content-notification-style-type-inbox');
  static final contentNotificationStyleTypeLatest = tr('content-notification-style-type-latest');
  static final contentNotificationStyleTypeItemized = tr('content-notification-style-type-itemized');

  static final messageEditedAppend = tr('message-edited-append');

  // Confirmations (use confirm*)
  static final confirmInvite = tr('confirm-invite');
  static final confirmInvites = tr('confirm-invites-multiple');
  static final confirmStartChat = tr('confirm-start-chat');
  static final confirmDeactivate = tr('prompt-confirm-deactivate');
  static final confirmAttemptChat = tr('confirm-attempt-chat');
  static final confirmAdvancedColors = tr('confirm-advanced-colors');
  static final confirmEnableNotifications =
      tr('confirm-enable-notifications', args: [Values.appName]);
  static final confirmAuthVerification = tr('confirm-auth-verification');
  static final confirmAcceptInvite = tr('confirm-invite-accept');
  static final confirmEncryption = tr('confirm-encryption');
  static final confirmGroupEncryption = tr('confirm-encryption-group');
  static final confirmModifySyncInterval = tr('content-sync-interval');
  static final confirmDeleteKeys = tr('confirm-delete-keys');

  static final confirmThanks = tr('content-thanks', args: [Values.appName]);
  static final confirmAlphaVersion = tr('confirm-alpha-version');
  static final confirmAlphaWarning = tr('confirm-alpha-warning');
  static final confirmAlphaWarningAlt = tr('confirm-alpha-warning-alt');
  static final confirmAppTermsOfService = tr('confirm-terms-of-service', args: [Values.appName]);
  static final confirmTermsOfServiceConclusion = tr('confirm-terms-of-service-alt');

  static String confirmLinkout(String url) => tr('confirm-linkout', args: [url]);

  static String confirmArchiveRooms({required Iterable<Room> rooms}) => rooms.length == 1
      ? tr('confirm-archive-chat-single', args: ['${rooms.first.name}', Values.appName])
      : tr('confirm-archive-chat-multi', args: ['${rooms.length}', Values.appName]);

  static String confirmDeleteRooms({required Iterable<Room> rooms}) => rooms.length == 1
      ? tr('confirm-delete-chat-single', args: ['${rooms.first.name}', Values.appName])
      : tr('confirm-delete-chat-multi', args: ['${rooms.length}', Values.appName]);

  static String confirmLeaveRooms({required Iterable<Room> rooms}) {
    final singleOrMulti = rooms.length == 1 ? 'single' : 'multi';

    var s = tr(
      'confirm-leave-chat-$singleOrMulti',
      args: [if (rooms.length == 1) '${rooms.first.name}' else '${rooms.length}'],
    );

    if (rooms.where((element) => element.type != 'public').isNotEmpty) {
      s += '\n${tr('confirm-leave-chat-$singleOrMulti-nonpublic')}';
    }

    return s;
  }

  static String confirmBlockUser(String? name) => tr('confirm-block-user', args: ['$name']);

  // Accessibility
  static final semanticsImageIntro = tr('semantics-image-intro');
  static final semanticsPrivateMessage = tr('semantics-image-private-message');
  static final semanticsIntroFinal = tr('semantics-image-intro-section-four');
  static final semanticsIntroThird = tr('semantics-image-intro-section-third');
  static final semanticsHomeDefault = tr('semantics-image-empty-chat-list');
  static final semanticsImageSignupUsername = tr('semantics-image-signup-username');
  static final semanticsImagePasswordReset = tr('semantics-image-password-reset');
  static final semanticsCreatePublicRoom = tr('semantics-create-public-room');

  // Labels
  static final labelProxyHost = tr('label-proxy-host');
  static final labelProxyPort = tr('label-proxy-port');
  static final labelProxyUsername = tr('label-proxy-username');
  static final labelProxyPassword = tr('label-proxy-password');
  static final labelPassword = tr('label-password');
  static final labelDefault = tr('label-default');

  // Tooltips
  static final tooltipProfileAndSettings = tr('tooltip-profile-settings');
  static final tooltipSearchChats = tr('tooltip-search-chats');
  static final tooltipSearchUnencrypted = tr('tooltip-search-unencrypted');
  static final tooltipCancelReply = tr('tooltip-cancel-reply');
  static final tooltipSearchUsers = tr('tooltip-search-users');
}
