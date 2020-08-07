// Dart imports:
import 'dart:async';
import 'package:http/http.dart' as http;

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:html/parser.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/jack/index.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

final protocol = DotEnv().env['PROTOCOL'];

class ResetSearchResults {}

class SetLoading {
  final bool loading;

  SetLoading({this.loading});
}

class SetSearchText {
  final String text;

  SetSearchText({this.text});
}

class SetHomeservers {
  final List<dynamic> homeservers;

  SetHomeservers({this.homeservers});
}

class UpdateHomeservers {
  final List<dynamic> homeservers;

  UpdateHomeservers({this.homeservers});
}

// sets the "since" variable for pagination
class SetSearchResults {
  final String since;
  final int totalResults;
  final bool hasMore;
  final String searchText;
  final List<dynamic> searchResults;

  SetSearchResults({
    this.searchResults,
    this.searchText,
    this.totalResults,
    this.hasMore,
    this.since,
  });
}

Future<String> fetchHomeserverIcon({dynamic homeserver}) async {
  String icon = "";
  try {
    final hostname = homeserver['hostname'];

    // get the root store
    final origins = hostname.toString().split('.');
    final rootorigin = origins.length > 1
        ? origins[origins.length - 2] + '.' + origins[origins.length - 1]
        : origins[0];
    final response = await http.get('https://$rootorigin');

    final document = parse(response.body);
    final favicon = document.querySelector('link[rel="shortcut icon"]');
    icon = favicon.attributes['href'].toString().contains('http')
        ? favicon.attributes['href']
        : 'https://$rootorigin/' +
            favicon.attributes['href']
                .replaceAll('...', '')
                .replaceAll('//', '/');
  } catch (error) {
    /** noop */
  }
  return icon;
}

ThunkAction<AppState> fetchHomeserverIcons() {
  return (Store<AppState> store) async {
    final homeservers = store.state.searchStore.homeservers;

    final faviconFetches = homeservers.map((homeserver) async {
      final iconUrl = await fetchHomeserverIcon(homeserver: homeserver);

      if (iconUrl.length <= 0) return homeserver;

      try {
        final response = await http.get(iconUrl);
        if (response.statusCode != 200) return homeserver;
      } catch (error) {
        /** noop */
        return homeserver;
      }

      final homeserverUpdated = Map.from(homeserver);
      homeserverUpdated['favicon'] = iconUrl;
      return homeserverUpdated;
    });

    final homeserversIconized = await Future.wait(faviconFetches);

    store.dispatch(UpdateHomeservers(
      homeservers: List.from(homeserversIconized),
    ));
  };
}

ThunkAction<AppState> fetchHomeservers() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));

    final List<dynamic> homeservers = await JackApi.fetchPublicServers();

    await store.dispatch(SetHomeservers(homeservers: homeservers));
    await store.dispatch(fetchHomeserverIcons());
    store.dispatch(SetLoading(loading: false));
  };
}

ThunkAction<AppState> searchHomeservers({String searchText}) {
  return (Store<AppState> store) async {
    List<dynamic> searchResults = store.state.searchStore.homeservers
        .where((homeserver) =>
            homeserver['hostname'].contains(searchText) ||
            homeserver['description'].contains(searchText))
        .toList();

    store.dispatch(SetSearchResults(
      searchText: searchText,
      searchResults: searchResults,
    ));
  };
}

/** 
 *  Search Rooms (Remote)
 */
ThunkAction<AppState> searchPublicRooms({String searchText}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.searchRooms(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        searchText: searchText,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final List<dynamic> rawPublicRooms = data['chunk'];
      final List<Room> convertedRooms =
          rawPublicRooms.map((room) => Room.fromJson(room)).toList();

      store.dispatch(SetSearchResults(
        since: data['next_batch'],
        searchResults: convertedRooms,
        totalResults: data['total_room_count_estimate'],
      ));
    } catch (error) {
      store.dispatch(
        addAlert(message: 'Failed to search rooms'),
      );
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/** 
 *  search requires remote access
 */
ThunkAction<AppState> searchUsers({String searchText}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.searchUsers(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        searchText: searchText,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final List<dynamic> rawUsers = data['results'];

      final List<User> searchResults =
          rawUsers.map((room) => User.fromJson(room)).toList();

      store.dispatch(SetSearchResults(
        since: data['next_batch'],
        searchResults: searchResults,
        totalResults: searchResults.length,
      ));
    } catch (error) {
      debugPrint('[searchPublicRooms] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> setSearchText({String text}) {
  return (Store<AppState> store) async {
    store.dispatch(SetSearchText(text: text));
  };
}

ThunkAction<AppState> clearSearchResults() {
  return (Store<AppState> store) async {
    store.dispatch(ResetSearchResults());
  };
}
