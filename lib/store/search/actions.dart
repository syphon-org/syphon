import 'dart:convert';
import 'dart:async';
import 'package:Tether/store/rooms/room/model.dart';
import 'package:Tether/global/libs/matrix/search.dart';
import 'package:Tether/store/user/model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/store/index.dart';

import 'package:Tether/global/libs/hello-matrix/index.dart';

final protocol = DotEnv().env['PROTOCOL'];

class ResetSearchResults {}

class SetLoading {
  final bool loading;

  SetLoading({this.loading});
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
  String since;
  int totalResults;
  bool hasMore;
  final List<dynamic> searchResults;

  SetSearchResults({
    this.searchResults,
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
  } catch (error) {}
  return icon;
}

ThunkAction<AppState> fetchHomeserverIcons() {
  return (Store<AppState> store) async {
    final homeservers = store.state.matrixStore.homeservers;

    homeservers.forEach((homeserver) async {
      final iconUrl = await fetchHomeserverIcon(homeserver: homeserver);

      if (iconUrl.length <= 0) {
        return;
      }

      final response = await http.get(iconUrl);

      if (response.statusCode != 200) {
        return;
      }

      homeserver['favicon'] = iconUrl;
      store.dispatch(UpdateHomeservers(homeservers: List.from(homeservers)));
    });
  };
}

ThunkAction<AppState> fetchHomeservers() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));
    final response = await http.get(HOMESERVER_SEARCH_SERVICE);
    final List<dynamic> homeservers = json.decode(response.body);

    store.dispatch(SetHomeservers(homeservers: homeservers));
    store.dispatch(SetLoading(loading: false));
    store.dispatch(fetchHomeserverIcons());
  };
}

ThunkAction<AppState> searchHomeservers({String searchText}) {
  return (Store<AppState> store) async {
    List<dynamic> searchResults = store.state.matrixStore.homeservers
        .where((homeserver) =>
            homeserver['hostname'].contains(searchText) ||
            homeserver['description'].contains(searchText))
        .toList();
    store.dispatch(SetSearchResults(
      searchResults: searchResults,
    ));
  };
}

/**
 *  TODO: filter is different from a search
 *  search requires remote access
 */
ThunkAction<AppState> searchPublicRooms({String searchText}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));
      final request = buildPublicRoomSearch(
        protocol: protocol,
        accessToken: store.state.userStore.user.accessToken,
        homeserver: store.state.userStore.homeserver,
        searchText: searchText,
      );

      final response = await http.post(
        request['url'],
        headers: request['headers'],
        body: json.encode(request['body']),
      );

      final data = json.decode(response.body);
      if (data['errcode'] != null) {
        throw data['error'];
      }

      final List<dynamic> rawPublicRooms = data['chunk'];
      final List<Room> convertedRooms =
          rawPublicRooms.map((room) => Room.fromJson(room)).toList();

      print('[searchPublicRooms] conversion successful');

      store.dispatch(SetSearchResults(
        since: data['next_batch'],
        searchResults: convertedRooms,
        totalResults: data['total_room_count_estimate'],
      ));
    } catch (error) {
      print('[searchPublicRooms] $error');
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
      final request = buildUserSearch(
        protocol: protocol,
        accessToken: store.state.userStore.user.accessToken,
        homeserver: store.state.userStore.homeserver,
        searchText: searchText,
      );

      final response = await http.post(
        request['url'],
        headers: request['headers'],
        body: json.encode(request['body']),
      );

      final data = json.decode(response.body);
      if (data['errcode'] != null) {
        throw data['error'];
      }

      print('[searchUsers] success');
      final List<dynamic> rawUsers = data['results'];

      final List<User> searchResults =
          rawUsers.map((room) => User.fromJson(room)).toList();

      // TODO: dispatch fetch user icons

      store.dispatch(SetSearchResults(
        since: data['next_batch'],
        searchResults: searchResults,
        totalResults: searchResults.length,
      ));
    } catch (error) {
      print('[searchPublicRooms] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> clearSearchResults() {
  return (Store<AppState> store) async {
    store.dispatch(ResetSearchResults());
  };
}
