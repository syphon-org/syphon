import 'package:Tether/domain/index.dart'; // TODO: remove need for store in view dependencies
import 'package:Tether/views/home/messages/message-details.dart';
import 'package:flutter/material.dart';

// Intro
import 'package:Tether/views/login/index.dart';
import 'package:Tether/views/signup/index.dart';
import 'package:Tether/views/signup/loading.dart';
import 'package:Tether/views/homesearch/index.dart';
import 'package:Tether/views/intro/index.dart';

// Home
import 'package:Tether/views/home/index.dart';
// import 'package:Tether/views/home/draft.dart';
import 'package:Tether/views/home/profile/index.dart';
import 'package:Tether/views/home/settings/index.dart';

// Messages
import 'package:Tether/views/home/messages/index.dart';
import 'package:Tether/views/home/messages/settings.dart';

// Settings
import 'package:Tether/views/home/settings/advanced.dart';
import 'package:Tether/views/home/settings/notifications.dart';
import 'package:Tether/views/home/settings/customization.dart';
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
      '/home': (BuildContext context) => Home(
            title: 'Tether',
          ),
      '/home/messages': (BuildContext context) => Messages(),
      '/home/messages/settings': (BuildContext context) => ChatSettingsScreen(),
      '/home/messages/details': (BuildContext context) => MessageDetails(),
      '/profile': (BuildContext context) => Profile(),
      '/notifications': (BuildContext context) => NotificationSettings(),
      '/advanced': (BuildContext context) => AdvancedScreen(),
      '/customization': (BuildContext context) => Customization(
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
