import 'package:syphon/global/values.dart';

import 'package:syphon/views/home/chat/details-chat.dart';
import 'package:syphon/views/home/chat/details-message.dart';
import 'package:syphon/views/home/search/search-groups.dart';
import 'package:syphon/views/home/search/search-users.dart';
import 'package:syphon/views/home/settings/chats.dart';
import 'package:syphon/views/home/settings/devices.dart';
import 'package:syphon/views/home/settings/password/index.dart';
import 'package:syphon/views/home/settings/privacy.dart';
import 'package:syphon/views/home/settings/storage.dart';
import 'package:syphon/views/home/settings/theming.dart';
import 'package:flutter/material.dart';

// Intro
import 'package:syphon/views/login/index.dart';
import 'package:syphon/views/signup/index.dart';
import 'package:syphon/views/signup/loading.dart';
import 'package:syphon/views/homesearch/index.dart';
import 'package:syphon/views/intro/index.dart';

// Home
import 'package:syphon/views/home/index.dart';
import 'package:syphon/views/home/profile/index.dart';
import 'package:syphon/views/home/settings/index.dart';

// Messages
import 'package:syphon/views/home/chat/index.dart';

// Settings
import 'package:syphon/views/home/settings/advanced.dart';
import 'package:syphon/views/home/settings/notifications.dart';
import 'package:redux/redux.dart';
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

class NavigationProvider {
  static getRoutes() {
    return <String, WidgetBuilder>{
      '/intro': (BuildContext context) => Intro(),
      '/login': (BuildContext context) => Login(),
      '/search_home': (BuildContext context) => HomeSearch(),
      '/signup': (BuildContext context) => SignupView(),
      '/verification': (BuildContext context) => VerificationView(),
      '/home': (BuildContext context) => Home(),
      '/home/chat': (BuildContext context) => ChatView(),
      '/home/chat/settings': (BuildContext context) => ChatDetailsView(),
      '/home/chat/details': (BuildContext context) => MessageDetails(),
      '/home/groups/search': (BuildContext context) => GroupSearchView(),
      '/home/user/search': (BuildContext context) => SearchUserView(),
      '/profile': (BuildContext context) => ProfileView(),
      '/notifications': (BuildContext context) => NotificationSettingsView(),
      '/advanced': (BuildContext context) => AdvancedView(),
      '/storage': (BuildContext context) => StorageView(),
      '/password': (BuildContext context) => PasswordView(),
      '/licenses': (BuildContext context) => LicensePage(
            applicationName: Values.appName,
          ),
      '/privacy': (BuildContext context) => PrivacyPreferences(),
      '/chat-preferences': (BuildContext context) => ChatPreferences(),
      '/theming': (BuildContext context) => Theming(),
      '/devices': (BuildContext context) => DevicesView(),
      '/settings': (BuildContext context) => SettingsScreen(),
      '/loading': (BuildContext context) => Loading(
            title: 'Loading',
          ),
    };
  }
}
