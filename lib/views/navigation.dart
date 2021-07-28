import 'package:flutter/material.dart';

import 'package:syphon/global/values.dart';
import 'package:syphon/views/home/chat/chat-detail-all-users-screen.dart';
import 'package:syphon/views/home/chat/chat-detail-screen.dart';
import 'package:syphon/views/home/chat/chat-detail-message-screen.dart';
import 'package:syphon/views/home/chat/chat-screen.dart';
import 'package:syphon/views/home/groups/group-create-public-screen.dart';
import 'package:syphon/views/home/groups/group-create-screen.dart';
import 'package:syphon/views/home/groups/invite-users-screen.dart';
import 'package:syphon/views/home/home-screen.dart';
import 'package:syphon/views/home/profile/profile-user-screen.dart';
import 'package:syphon/views/home/profile/profile-screen.dart';
import 'package:syphon/views/home/search/search-groups-screen.dart';
import 'package:syphon/views/home/search/search-chats-screen.dart';
import 'package:syphon/views/home/search/search-users-screen.dart';
import 'package:syphon/views/home/settings/advanced-settings-screen.dart';
import 'package:syphon/views/home/settings/blocked-screen.dart';
import 'package:syphon/views/home/settings/settings-chats-screen.dart';
import 'package:syphon/views/home/settings/settings-devices-screen.dart';
import 'package:syphon/views/home/settings/settings-screen.dart';
import 'package:syphon/views/home/settings/settings-notifications-screen.dart';
import 'package:syphon/views/home/settings/password/password-update-screen.dart';
import 'package:syphon/views/home/settings/settings-privacy-screen.dart';
import 'package:syphon/views/home/settings/settings-storage-screen.dart';
import 'package:syphon/views/home/settings/settings-theming-screen.dart';
import 'package:syphon/views/intro/login/forgot/password-forgot-screen.dart';
import 'package:syphon/views/intro/login/forgot/password-reset-screen.dart';
import 'package:syphon/views/intro/search/search-homeserver-screen.dart';
import 'package:syphon/views/intro/intro-screen.dart';
import 'package:syphon/views/intro/login/login-screen.dart';
import 'package:syphon/views/intro/signup/signup-screen.dart';
import 'package:syphon/views/intro/signup/loading-screen.dart';
import 'package:syphon/views/intro/signup/verification-screen.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  static Future clearTo(String routeName, BuildContext context) {
    final navigator = navigatorKey.currentState;

    if (navigator == null) return Future.value();

    return navigator.pushNamedAndRemoveUntil(routeName, (_) => false);
  }
}

class NavigationPaths {
  // Onboarding
  static const loading = '/loading';
  static const intro = '/intro';
  static const login = '/login';
  static const signup = '/signup';
  static const forgot = '/forgot';
  static const reset = '/reset';
  static const verification = '/verification';
  static const searchHomeservers = '/search/homeservers';

  // Main (Authed)
  static const home = '/home';

  // Search
  static const searchAll = '/home/search';
  static const searchChats = '/home/search/chats';
  static const searchUsers = '/home/search/users';
  static const searchGroups = '/home/search/groups';

  // Users
  static const userInvite = '/home/user/invite';
  static const userDetails = '/home/user/details';

  // Groups
  static const groupCreate = '/home/groups/create';
  static const groupCreatePublic = '/home/groups/create/public';

  // Chats and Messages
  static const chat = '/home/chat';
  static const chatUsers = '/home/chat/users';
  static const chatDetails = '/home/chat/details';
  static const messageDetails = '/home/message/details';

  // Settings
  static const settings = '/home/settings';
  static const settingsChat = '/home/settings/chat';
  static const settingsProfile = '/home/settings/profile';
  static const settingsStorage = '/home/settings/storage';
  static const settingsPrivacy = '/home/settings/privacy';
  static const settingsDevices = '/home/settings/devices';
  static const settingsBlocked = '/home/settings/blocked';
  static const settingsPassword = '/home/settings/password';
  static const settingsAdvanced = '/home/settings/advanced';
  static const settingsNotifications = '/home/settings/notifications';

  // Settings (Global)
  static const theming = '/settings/theming';

  // Misc
  static const licenses = '/licenses';
}

class NavigationProvider {
  static Map<String, Widget Function(BuildContext)> getRoutes() => <String, WidgetBuilder>{
        NavigationPaths.intro: (BuildContext context) => const IntroScreen(),
        NavigationPaths.login: (BuildContext context) => const LoginScreen(),
        NavigationPaths.signup: (BuildContext context) => const SignupScreen(),
        NavigationPaths.forgot: (BuildContext context) => const ForgotPasswordScreen(),
        NavigationPaths.reset: (BuildContext context) => const ResetPasswordScreen(),
        NavigationPaths.searchHomeservers: (BuildContext context) => const SearchHomeserverScreen(),
        NavigationPaths.verification: (BuildContext context) => const VerificationScreen(),
        NavigationPaths.home: (BuildContext context) => const HomeScreen(),
        NavigationPaths.chat: (BuildContext context) => const ChatScreen(),
        NavigationPaths.chatDetails: (BuildContext context) => const ChatDetailsScreen(),
        NavigationPaths.messageDetails: (BuildContext context) => const MessageDetailsScreen(),
        NavigationPaths.chatUsers: (BuildContext context) => const ChatUsersDetailScreen(),
        NavigationPaths.searchUsers: (BuildContext context) => const SearchUserScreen(),
        NavigationPaths.userDetails: (BuildContext context) => const UserProfileScreen(),
        NavigationPaths.userInvite: (BuildContext context) => const InviteUsersScreen(),
        NavigationPaths.searchChats: (BuildContext context) => const ChatSearchScreen(),
        NavigationPaths.searchGroups: (BuildContext context) => const GroupSearchScreen(),
        NavigationPaths.groupCreate: (BuildContext context) => const CreateGroupScreen(),
        NavigationPaths.groupCreatePublic: (BuildContext context) => const CreatePublicGroupScreen(),
        NavigationPaths.settingsProfile: (BuildContext context) => const ProfileScreen(),
        NavigationPaths.settingsNotifications: (BuildContext context) => const NotificationSettingsScreen(),
        NavigationPaths.settingsAdvanced: (BuildContext context) => const AdvancedSettingsScreen(),
        NavigationPaths.settingsStorage: (BuildContext context) => const StorageSettingsScreen(),
        NavigationPaths.settingsPassword: (BuildContext context) => const PasswordUpdateScreen(),
        NavigationPaths.licenses: (BuildContext context) =>
            const LicensePage(applicationName: Values.appName),
        NavigationPaths.settingsPrivacy: (BuildContext context) => const PrivacySettingsScreen(),
        NavigationPaths.settingsChat: (BuildContext context) => const ChatsSettingsScreen(),
        NavigationPaths.theming: (BuildContext context) => const ThemingSettingsScreen(),
        NavigationPaths.settingsDevices: (BuildContext context) => DevicesScreen(),
        NavigationPaths.settings: (BuildContext context) => const SettingsScreen(),
        NavigationPaths.settingsBlocked: (BuildContext context) => const BlockedScreen(),
        NavigationPaths.loading: (BuildContext context) => const LoadingScreen(),
      };
}
