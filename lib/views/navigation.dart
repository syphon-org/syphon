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
import 'package:syphon/views/home/search/search-rooms-screen.dart';
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

  static Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  static Future<dynamic> clearTo(String routeName, BuildContext context) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(routeName, (_) => false);
  }
}

// TODO: finish converting over to NavigationPaths for all routes
class NavigationPaths {
  static const intro = '/intro';
  static const login = '/login';
  static const signup = '/signup';
  static const forgot = '/forgot';
  static const reset = '/reset';
  static const searchHomeservers = '/search/homeservers';
  static const searchRooms = '/home/rooms/search';
  static const userDetails = '/home/user/details';
  static const verification = '/verification';
  static const theming = '/theming';
  static const home = '/home';
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
        '/home/chat': (BuildContext context) => const ChatScreen(),
        '/home/chat/settings': (BuildContext context) => const ChatDetailsScreen(),
        '/home/chat/details': (BuildContext context) => const MessageDetailsScreen(),
        '/home/chat/users': (BuildContext context) => const ChatUsersDetailScreen(),
        '/home/user/search': (BuildContext context) => const SearchUserScreen(),
        '/home/user/details': (BuildContext context) => const UserProfileScreen(),
        '/home/user/invite': (BuildContext context) => const InviteUsersScreen(),
        '/home/rooms/search': (BuildContext context) => const RoomSearchScreen(),
        '/home/groups/search': (BuildContext context) => const GroupSearchScreen(),
        '/home/groups/create': (BuildContext context) => const CreateGroupScreen(),
        '/home/groups/create/public': (BuildContext context) => const CreatePublicGroupScreen(),
        '/profile': (BuildContext context) => const ProfileScreen(),
        '/notifications': (BuildContext context) => const NotificationSettingsScreen(),
        '/advanced': (BuildContext context) => const AdvancedSettingsScreen(),
        '/storage': (BuildContext context) => const StorageSettingsScreen(),
        '/password': (BuildContext context) => const PasswordUpdateView(),
        '/licenses': (BuildContext context) => const LicensePage(applicationName: Values.appName),
        '/privacy': (BuildContext context) => const PrivacySettingsScreen(),
        '/chat-preferences': (BuildContext context) => const ChatsSettingsScreen(),
        NavigationPaths.theming: (BuildContext context) => const ThemingSettingsScreen(),
        '/devices': (BuildContext context) => DevicesScreen(),
        '/settings': (BuildContext context) => const SettingsScreen(),
        '/blocked': (BuildContext context) => const BlockedScreen(),
        '/loading': (BuildContext context) => const LoadingScreen(),
      };
}
