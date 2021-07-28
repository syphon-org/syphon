///
/// String Keys
///
/// Maps to all keys used within files located at
///
/// - assets/translations/*.json
///
/// Glossary is based on en.json
///
class StringKeys {
  // titles (screens / views)
  static const titleProfile = 'title-view-profile';
  static const titleSearchGroups = 'title-view-search-groups';
  static const titleSearchUsers = 'title-view-search-users';
  static const titleInviteUsers = 'title-view-invite-users';
  static const titleChatUsers = 'title-view-chat-users';
  static const titleCreateGroup = 'title-view-create-group';
  static const titleCreateGroupPublic = 'title-view-create-group-public';
  static const titleDevices = 'title-view-devices';
  static const titleSettings = 'title-view-settings';
  static const titleTheming = 'title-view-theming';
  static const titleAdvanced = 'title-view-advanced';
  static const titleInvite = 'title-view-invite';
  static const titleChatSettings = 'title-view-settings-chat';
  static const titlePrivacy = 'title-view-privacy';
  static const titleHomeserverSearch = 'title-view-homeserver-search';
  static const titleEmailVerification = 'title-user-verification';

  // titles (dialogs)
  static const titleDialogEncryption = 'title-dialog-encryption';
  static const titleDialogCaptcha = 'title-dialog-captcha';
  static const titleDialogTerms = 'title-dialog-terms';
  static const titleDialogTermsAlpha = 'title-dialog-terms-alpha';
  static const titleDialogEmailRequirement = 'title-dialog-email-requirement';
  static const titleDialogSignupEmailVerification = 'title-dialog-email-requirement-verified';
  static const titleConfirmPassword = 'title-confirm-password';
  static const titleConfirmDeleteDevices = 'title-view-delete-devices';
  static const titleConfirmDeleteKeys = 'title-dialog-delete-keys';
  static const titleConfirmEmail = 'title-confirm-email';

  // Labels
  static const labelUsers = 'label-users';
  static const labelUsersRecent = 'label-users-recent';
  static const labelUsersResults = 'label-users-results';
  static const labelKnownUsers = 'label-users-known';
  static const labelSyncing = 'label-syncing';
  static const labelSearching = 'label-searching';
  static const labelChatDefault = 'label-chat-default';
  static const labelSearchHomeservers = 'label-search-homeservers';
  static const labelSearchUser = 'label-search-user';
  static const labelSearchUsers = 'label-search-users';
  static const labelMessagesEmpty = 'label-messages-empty';
  static const labelMessageEncrypted = 'label-message-encrypted';
  static const labelMessageMatrix = 'label-message-matrix';
  static const labelMessageMatrixUnencrypted = 'label-message-matrix-unencrypted';
  static const labelGroupsEmpty = 'label-groups-empty';

  // Labels (inputs)
  static const labelEmail = 'label-email';

  // Buttons
  static const buttonLogin = 'button-login';
  static const buttonLoginSSO = 'button-login-sso';
  static const buttonSaveGeneric = 'button-save-generic';
  static const buttonNext = 'button-next';
  static const buttonFinish = 'button-finish';
  static const buttonLetsChat = 'button-start-chat';
  static const buttonCreate = 'button-create';
  static const buttonCancel = 'button-cancel';
  static const buttonQuit = 'button-quit';
  static const buttonConfirm = 'button-confirm';
  static const buttonDeleteKeys = 'button-delete-keys';

  // Buttons (Text Buttons)
  static const buttonTextSignupAction = 'button-text-signup-action';
  static const buttonTextSignupQuestion = 'button-text-signup-question';
  static const buttonTextSeeUsers = 'button-text-see-users';
  static const buttonTextExistingUser = 'button-text-existing-user';
  static const buttonTextLogin = 'button-text-login';
  static const buttonTextLoadCaptcha = 'button-text-load-captcha';
  static const buttonTextConfirmed = 'button-text-confirmed';

  // List Items
  static const listItemSettingsNotification = 'list-item-settings-notification';
  static const listItemSettingsChat = 'list-item-settings-chat';
  static const listItemSettingsPrivacy = 'list-item-settings-privacy';
  static const listItemSettingsSms = 'list-item-settings-sms';
  static const listItemSettingsLogout = 'list-item-settings-logout';

  // Alerts
  static const alertRestartAppEffect = 'alert-restart-app-effect';
  static const alertInviteUserUnknown = 'alert-invite-user-unknown';
  static const alertFeatureInProgress = 'alert-feature-in-progress';
  static const alertMessageFailed = 'alert-message-failed';
  static const alertHomeserverInvalid = 'alert-homeserver-invalid';
  static const alertAppRestartEffect = 'alert-restart-app-effect';

  // Content
  static const contentIntroSectionOne = 'content-intro-section-one';
  static const contentIntroSectionTwo = 'content-intro-section-two';
  static const contentIntroSectionTwoPartTwo = 'content-intro-section-two-part-two';
  static const contentIntroSectionTwoPartThree = 'content-intro-section-two-part-three';
  static const contentIntroSectionThree = 'content-intro-section-three';
  static const contentIntroSectionFour = 'content-intro-section-four';
  static const contentDialogDevicesDelete = 'content-dialog-devices-delete';
  static const contentDialogDevicesKeyExport = 'content-dialog-devices-key-export';
  static const contentNotificationBackground = 'content-notification-background';
  static const contentSignupCaptchaRequirement = 'content-signup-captcha-requirement';

  // Context (Dialogs)
  static const contentConfirmDeleteKeys = 'confirmation-delete-keys';
  static const contentSignupEmailVerification = 'content-signup-email-verification';
  static const contentForgotEmailVerification = 'content-forgot-email-verification';
  static const contentConfirmPasswordReset = 'content-confirm-password-reset';

  // Dialogs
  static const confirmationInvite = 'confirmation-invite';
  static const confirmationStartChat = 'confirmation-start-chat';
  static const confirmationAttemptChat = 'confirmation-attempt-chat';
  static const confirmationTermsOfService = 'confirmation-terms-of-service';
  static const confirmationNotifications = 'confirmation-notifications';
  static const confirmationAuthVerification = 'confirmation-auth-verification';
  static const confirmationThanks = 'confirmation-thanks';
  static const confirmationAlphaVersion = 'confirmation-alpha-version';
  static const confirmationAlphaWarning = 'confirmation-alpha-warning';
  static const confirmationAlphaWarningAlt = 'confirmation-alpha-warning-alt';
  static const confirmationTermsOfServiceAlt = 'confirmation-terms-of-service-alt';
  static const confirmationInviteAccept = 'confirmation-invite-accept';
  static const confirmationEncryption = 'confirmation-encryption';
  static const confirmationEncryptionGroup = 'confirmation-encryption-group';

  // Dialogs (Alt)
  static const promptHomeserverSelect = 'prompt-homeserver-select';
  static const promptConfirmDeactivate = 'prompt-confirm-deactivate';

  // Accessibility
  static const semanticsImageSendUnencrypted = 'semantics-image-send-unencrypted';
  static const semnaticsImageIntroSectionOne = 'semnatics-image-intro';
  static const semnaticsImageIntroSectionTwo = 'semnatics-image-private-message';
  static const semnaticsImageIntroSectionThird = 'semnatics-image-intro-section-third';
  static const semnaticsImageIntroSectionFour = 'semnatics-image-intro-section-four';
  static const semanticsImageEmptyChatList = 'semantics-image-empty-chat-list';
  static const semanticsImageTermsOfService = 'semantics-image-terms-of-service';
}
