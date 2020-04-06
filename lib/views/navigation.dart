import 'package:Tether/domain/index.dart'; // TODO: remove need for store in view dependencies
import 'package:flutter/material.dart';

// Intro
import 'package:Tether/views/login/index.dart';
import 'package:Tether/views/signup/index.dart';
import 'package:Tether/views/homesearch/index.dart';
import 'package:Tether/views/intro/index.dart';
import 'package:Tether/views/loading.dart';

// Home
import 'package:Tether/views/home/index.dart';
import 'package:Tether/views/home/profile/index.dart';
import 'package:Tether/views/home/settings/index.dart';

// Messages
import 'package:Tether/views/home/messages/index.dart';
import 'package:Tether/views/home/messages/draft.dart';

// Settings
import 'package:Tether/views/home/settings/advanced.dart';
import 'package:Tether/views/home/settings/notifications.dart';
import 'package:Tether/views/home/settings/appearance.dart';
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
      '/home': (BuildContext context) => Home(
            title: 'Tether',
          ),
      '/draft': (BuildContext context) => Draft(),
      '/profile': (BuildContext context) => Profile(),
      '/home/messages': (BuildContext context) => Messages(),
      '/notifications': (BuildContext context) => NotificationSettings(),
      '/advanced': (BuildContext context) => AdvancedScreen(),
      '/appearance': (BuildContext context) => ApperanceScreen(
            title: 'Customization',
          ),
      '/settings': (BuildContext context) => SettingsScreen(
            title: 'Settings',
          ),
      '/loading': (BuildContext context) => Loading(
            title: 'Loading',
          ),
    };
  }
}
