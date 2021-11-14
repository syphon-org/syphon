import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/https.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

class SetLoading {
  final bool? loading;

  SetLoading({this.loading});
}

class SetSearchText {
  final String? text;

  SetSearchText({this.text});
}

class SetHomeservers {
  final List<dynamic>? homeservers;

  SetHomeservers({this.homeservers});
}

class UpdateHomeservers {
  final List<dynamic>? homeservers;

  UpdateHomeservers({this.homeservers});
}

// sets the "since" variable for pagination
class SetSearchResults {
  final String? since;
  final int? totalResults;
  final bool? hasMore;
  final String? searchText;
  final List<dynamic>? searchResults;

  SetSearchResults({
    this.searchResults,
    this.searchText,
    this.totalResults,
    this.hasMore,
    this.since,
  });
}

class SearchMessages {
  final String searchText;

  SearchMessages({required this.searchText});
}

class SearchMessageResults {
  final List<Message> results;

  SearchMessageResults({required this.results});
}

class ResetSearchResults {}

Future<String?> fetchFavicon({String? url}) async {
  try {
    // get the root store
    final origins = url.toString().split('.');
    final baseUrl = origins.length > 1
        ? origins[origins.length - 2] + '.' + origins[origins.length - 1]
        : origins[0];
    final fullUrl = 'https://$baseUrl';

    final uri = Uri.parse(fullUrl);

    final response = await httpClient.get(uri).timeout(
          const Duration(seconds: 4),
        );

    final document = parse(response.body);
    final faviconIcon = document.querySelector('link[rel="icon"]');
    final faviconShort = document.querySelector('link[rel="shortcut icon"]');
    final favicon = faviconShort ?? faviconIcon!;

    var faviconUrl = fullUrl;

    if (favicon.attributes['href'].toString().contains('http')) {
      return favicon.attributes['href'];
    }

    if (!favicon.attributes['href'].toString().startsWith('/')) {
      faviconUrl += '/';
    }

    return faviconUrl + favicon.attributes['href']!.replaceAll('...', '').replaceAll('//', '/');
  } catch (error) {
    printError(error.toString());
  }

  return null;
}

// Delay searching if one has previously just been scheduled
ThunkAction<AppState> searchMessages(String searchText) {
  return (Store<AppState> store) async {
    if (searchText.isEmpty) {
      return;
    }
    store.dispatch(SearchMessages(
      searchText: searchText,
    ));
  };
}

ThunkAction<AppState> searchHomeservers({String? searchText}) {
  return (Store<AppState> store) async {
    final List<Homeserver> searchResults = (store.state.searchStore.homeservers as List<Homeserver>)
        .where((homeserver) =>
            homeserver.hostname!.contains(searchText!) ||
            homeserver.description!.contains(searchText))
        .toList();

    store.dispatch(SetSearchResults(
      searchText: searchText,
      searchResults: searchResults,
    ));
  };
}

///  Search Rooms (Locally)
ThunkAction<AppState> searchRooms({String? searchText}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final rooms = store.state.roomStore.roomList;
      List<Room> searchResults = List.from(rooms.where((room) => !room.direct));

      if (searchText!.isNotEmpty) {
        searchResults = List.from(
          rooms.where((room) {
            final fulltext = room.name! + room.alias! + room.topic!;
            return fulltext.contains(searchText);
          }),
        );
      }

      store.dispatch(SetSearchResults(
        searchText: searchText,
        searchResults: searchResults,
      ));
    } catch (error) {
      /**noop */
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

///  Search Rooms (Remote)
ThunkAction<AppState> searchRoomsPublic({String? searchable}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final homeserverName = store.state.authStore.user.homeserverName;

      var searchText = searchable!;
      var searchServer = homeserverName;

      if (searchText.contains(':')) {
        final filteredText = searchText.split(':');
        searchText = filteredText[0];
        searchServer = filteredText[1];
      }

      final isUrl = RegExp(Values.urlRegex).hasMatch(searchServer!);

      final data = await MatrixApi.searchRooms(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        searchText: searchText,
        server: isUrl ? searchServer : homeserverName,
        global: true,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final List<dynamic> rawPublicRooms = data['chunk'];
      final List<Room> convertedRooms =
          rawPublicRooms.map((room) => Room.fromMatrix(room)).toList();

      store.dispatch(SetSearchResults(
        since: data['next_batch'],
        searchResults: convertedRooms,
        totalResults: data['total_room_count_estimate'],
      ));
    } catch (error) {
      store.dispatch(addAlert(
        origin: 'searchPublicRooms',
        message: 'Failed to search rooms',
        error: error,
      ));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

///  search requires remote access
ThunkAction<AppState> searchUsers({String? searchText}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.searchUsers(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        searchText: searchText,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final List<dynamic> rawUsers = data['results'];

      final List<User> searchResults = rawUsers.map((room) => User.fromMatrix(room)).toList();

      store.dispatch(SetSearchResults(
        since: data['next_batch'],
        searchResults: searchResults,
        totalResults: searchResults.length,
      ));
    } catch (error) {
      printError('[searchPublicRooms] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> setSearchText({String? text}) {
  return (Store<AppState> store) async {
    store.dispatch(SetSearchText(text: text));
  };
}

ThunkAction<AppState> clearSearchResults() {
  return (Store<AppState> store) async {
    store.dispatch(ResetSearchResults());
  };
}
