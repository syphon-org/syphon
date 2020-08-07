// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:syphon/global/values.dart';
import 'package:syphon/views/home/chat/details-all-users.dart';
import 'package:syphon/views/home/chat/details-chat.dart';
import 'package:syphon/views/home/chat/details-message.dart';
import 'package:syphon/views/home/chat/index.dart';
import 'package:syphon/views/home/groups/group-create-public.dart';
import 'package:syphon/views/home/groups/invite-users.dart';
import 'package:syphon/views/home/index.dart';
import 'package:syphon/views/home/profile/details-user.dart';
import 'package:syphon/views/home/profile/index.dart';
import 'package:syphon/views/home/search/search-groups.dart';
import 'package:syphon/views/home/search/search-users.dart';
import 'package:syphon/views/home/settings/advanced.dart';
import 'package:syphon/views/home/settings/chats.dart';
import 'package:syphon/views/home/settings/devices.dart';
import 'package:syphon/views/home/settings/index.dart';
import 'package:syphon/views/home/settings/notifications.dart';
import 'package:syphon/views/home/settings/password/index.dart';
import 'package:syphon/views/home/settings/privacy.dart';
import 'package:syphon/views/home/settings/storage.dart';
import 'package:syphon/views/home/settings/theming.dart';
import 'package:syphon/views/search/search-homeservers.dart';
import 'package:syphon/views/intro/index.dart';
import 'package:syphon/views/login/index.dart';
import 'package:syphon/views/signup/index.dart';
import 'package:syphon/views/signup/loading.dart';
import 'package:syphon/views/signup/verification.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();

  static Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState.pushNamed(routeName);
  }

  static Future<dynamic> clearTo(String routeName, BuildContext context) {
    return navigatorKey.currentState
        .pushNamedAndRemoveUntil(routeName, (_) => false);
  }
}

class NavigationRouteIds {
  static const Intro = '/intro';
  static const Login = '/login';
  static const SearchHomeservers = '/search/homeservers';
  static const Signup = '/signup';
  static const VerificationView = '/verification';
}

class NavigationProvider {
  static getRoutes() => <String, WidgetBuilder>{
        '/intro': (BuildContext context) => Intro(),
        '/login': (BuildContext context) => Login(),
        '/signup': (BuildContext context) => SignupView(),
        '/search/homeservers': (BuildContext context) => SearchHomeservers(),
        '/verification': (BuildContext context) => VerificationView(),
        '/home': (BuildContext context) => Home(),
        '/home/chat': (BuildContext context) => ChatView(),
        '/home/chat/settings': (BuildContext context) => ChatDetailsView(),
        '/home/chat/details': (BuildContext context) => MessageDetails(),
        '/home/chat/users': (BuildContext context) => ChatUsersDetailView(),
        '/home/user/search': (BuildContext context) => SearchUserView(),
        '/home/user/details': (BuildContext context) => UserDetailsView(),
        '/home/user/invite': (BuildContext context) => InviteUsersView(),
        '/home/groups/search': (BuildContext context) => GroupSearchView(),
        '/home/groups/create': (BuildContext context) =>
            CreateGroupPublicView(),
        '/home/groups/create-public': (BuildContext context) =>
            CreateGroupPublicView(),
        '/profile': (BuildContext context) => ProfileView(),
        '/notifications': (BuildContext context) => NotificationSettingsView(),
        '/advanced': (BuildContext context) => AdvancedView(),
        '/storage': (BuildContext context) => StorageView(),
        '/password': (BuildContext context) => PasswordView(),
        '/licenses': (BuildContext context) =>
            LicensePage(applicationName: Values.appName),
        '/privacy': (BuildContext context) => PrivacyPreferences(),
        '/chat-preferences': (BuildContext context) => ChatPreferences(),
        '/theming': (BuildContext context) => Theming(),
        '/devices': (BuildContext context) => DevicesView(),
        '/settings': (BuildContext context) => SettingsScreen(),
        '/loading': (BuildContext context) => Loading(),
      };
}
