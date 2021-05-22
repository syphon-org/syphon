// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:syphon/global/values.dart';
import 'package:syphon/views/home/chat/details-all-users.dart';
import 'package:syphon/views/home/chat/details-chat.dart';
import 'package:syphon/views/home/chat/details-message.dart';
import 'package:syphon/views/home/chat/index.dart';
import 'package:syphon/views/home/groups/group-create-public.dart';
import 'package:syphon/views/home/groups/group-create.dart';
import 'package:syphon/views/home/groups/invite-users.dart';
import 'package:syphon/views/home/HomeScreen.dart';
import 'package:syphon/views/home/profile/details-user.dart';
import 'package:syphon/views/home/profile/index.dart';
import 'package:syphon/views/home/search/search-groups.dart';
import 'package:syphon/views/home/search/search-rooms.dart';
import 'package:syphon/views/home/search/search-users.dart';
import 'package:syphon/views/home/settings/advanced.dart';
import 'package:syphon/views/home/settings/blocked.dart';
import 'package:syphon/views/home/settings/chats.dart';
import 'package:syphon/views/home/settings/devices.dart';
import 'package:syphon/views/home/settings/index.dart';
import 'package:syphon/views/home/settings/notifications.dart';
import 'package:syphon/views/home/settings/password/index.dart';
import 'package:syphon/views/home/settings/privacy.dart';
import 'package:syphon/views/home/settings/storage.dart';
import 'package:syphon/views/home/settings/theming.dart';
import 'package:syphon/views/login/forgot/PasswordForgotScreen.dart';
import 'package:syphon/views/login/forgot/PasswordResetScreen.dart';
import 'package:syphon/views/search/SearchHomeserverScreen.dart';
import 'package:syphon/views/intro/IntroScreen.dart';
import 'package:syphon/views/login/LoginScreen.dart';
import 'package:syphon/views/signup/SignupScreen.dart';
import 'package:syphon/views/signup/LoadingScreen.dart';
import 'package:syphon/views/signup/VerificationScreen.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();

  static Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  static Future<dynamic> clearTo(String routeName, BuildContext context) {
    return navigatorKey.currentState!
        .pushNamedAndRemoveUntil(routeName, (_) => false);
  }
}

class NavigationProvider {
  static getRoutes() => <String, WidgetBuilder>{
        '/intro': (BuildContext context) => IntroScreen(),
        '/login': (BuildContext context) => LoginScreen(),
        '/signup': (BuildContext context) => SignupScreen(),
        '/forgot': (BuildContext context) => ForgotPasswordScreen(),
        '/reset': (BuildContext context) => ResetPasswordScreen(),
        '/search/homeservers': (BuildContext context) =>
            SearchHomeserverScreen(),
        '/verification': (BuildContext context) => VerificationScreen(),
        '/home': (BuildContext context) => HomeScreen(),
        '/home/chat': (BuildContext context) => ChatView(),
        '/home/chat/settings': (BuildContext context) => ChatDetailsView(),
        '/home/chat/details': (BuildContext context) => MessageDetails(),
        '/home/chat/users': (BuildContext context) => ChatUsersDetailView(),
        '/home/user/search': (BuildContext context) => SearchUserView(),
        '/home/user/details': (BuildContext context) => UserDetailsView(),
        '/home/user/invite': (BuildContext context) => InviteUsersView(),
        '/home/rooms/search': (BuildContext context) => RoomSearchView(),
        '/home/groups/search': (BuildContext context) => GroupSearchView(),
        '/home/groups/create': (BuildContext context) => CreateGroupView(),
        '/home/groups/create/public': (BuildContext context) =>
            CreateGroupPublicView(),
        '/profile': (BuildContext context) => ProfileView(),
        '/notifications': (BuildContext context) => NotificationSettingsView(),
        '/advanced': (BuildContext context) => AdvancedView(),
        '/storage': (BuildContext context) => StorageView(),
        '/password': (BuildContext context) => PasswordUpdateView(),
        '/licenses': (BuildContext context) =>
            LicensePage(applicationName: Values.appName),
        '/privacy': (BuildContext context) => PrivacyPreferences(),
        '/chat-preferences': (BuildContext context) => ChatPreferences(),
        '/theming': (BuildContext context) => Theming(),
        '/devices': (BuildContext context) => DevicesView(),
        '/settings': (BuildContext context) => SettingsScreen(),
        '/blocked': (BuildContext context) => BlockedUsersView(),
        '/loading': (BuildContext context) => LoadingScreen(),
      };
}
