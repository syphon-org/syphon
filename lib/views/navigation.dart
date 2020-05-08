import 'package:Tether/store/index.dart'; // TODO: remove need for store in view dependencies

import 'package:Tether/views/home/chat/details-chat.dart';
import 'package:Tether/views/home/chat/details-message.dart';
import 'package:Tether/views/home/search/seach-groups.dart';
import 'package:Tether/views/home/search/search-users.dart';
import 'package:Tether/views/home/settings/chats.dart';
import 'package:Tether/views/home/settings/devices.dart';
import 'package:Tether/views/home/settings/privacy.dart';
import 'package:Tether/views/home/settings/theming.dart';
import 'package:flutter/material.dart';

// Intro
import 'package:Tether/views/login/index.dart';
import 'package:Tether/views/signup/index.dart';
import 'package:Tether/views/signup/loading.dart';
import 'package:Tether/views/homesearch/index.dart';
import 'package:Tether/views/intro/index.dart';

// Home
import 'package:Tether/views/home/index.dart';
import 'package:Tether/views/home/profile/index.dart';
import 'package:Tether/views/home/settings/index.dart';

// Messages
import 'package:Tether/views/home/chat/index.dart';

// Settings
import 'package:Tether/views/home/settings/advanced.dart';
import 'package:Tether/views/home/settings/notifications.dart';
import 'package:redux/redux.dart';

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

// https://stackoverflow.com/questions/50196913/how-to-change-navigation-animation-using-flutter
// TODO: consistant transition styles
class NavigationProvider {
  static getRoutes(Store<AppState> store) {
    return <String, WidgetBuilder>{
      '/intro': (BuildContext context) => Intro(),
      '/login': (BuildContext context) => Login(store: store),
      '/search_home': (BuildContext context) => HomeSearch(
            title: 'Find Your Homeserver',
            store: store,
          ),
      '/signup': (BuildContext context) => Signup(
            title: 'Signup',
            store: store,
          ),
      '/home': (BuildContext context) => Home(),
      '/home/chat': (BuildContext context) => ChatView(),
      '/home/chat/settings': (BuildContext context) => ChatDetailsView(),
      '/home/chat/details': (BuildContext context) => MessageDetails(),
      '/home/groups/search': (BuildContext context) => GroupSearchView(
            title: 'Explore Groups',
          ),
      '/home/user/search': (BuildContext context) => SearchUserView(
            title: 'Search Users',
          ),
      '/profile': (BuildContext context) => ProfileView(),
      '/notifications': (BuildContext context) => NotificationSettings(),
      '/advanced': (BuildContext context) => AdvancedScreen(),
      '/privacy': (BuildContext context) => PrivacyPreferences(
            title: 'Privacy',
          ),
      '/chat-preferences': (BuildContext context) => ChatPreferences(
            title: 'Chat Preferences',
          ),
      '/theming': (BuildContext context) => Theming(
            title: 'Theming',
          ),
      '/devices': (BuildContext context) => DevicesView(),
      '/settings': (BuildContext context) => SettingsScreen(
            title: 'Settings',
          ),
      '/loading': (BuildContext context) => Loading(
            title: 'Loading',
          ),
    };
  }
}
