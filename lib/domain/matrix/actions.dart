import 'dart:convert';
import 'dart:async';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/domain/index.dart';

import 'package:Tether/global/libs/hello-matrix/index.dart';

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

class SetSearchResults {
  final List<dynamic> searchResults;

  SetSearchResults({this.searchResults});
}

Future<String> fetchHomeserverIcon({dynamic homeserver}) async {
  String icon = "";
  try {
    final hostname = homeserver['hostname'];

    // get the root domain
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
    store.dispatch(SetSearchResults(searchResults: searchResults));
  };
}
