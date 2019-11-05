import 'dart:convert';
import 'dart:async';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/domain/index.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:html/dom.dart';

const HOMESERVER_SEARCH_SERVICE =
    'https://www.hello-matrix.net/public_servers.php?format=json&only_public=true&show_from=Switzerland+%28Hosttech%29';

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
    var origin = homeserver['hostname'];
    var response = await http.get('https://$origin');

    var document = parse(response.body);
    var favicons = document.querySelectorAll('link[rel="shortcut icon"]');
    if (favicons.length != 0) {
      icon = 'https://$origin/' +
          favicons[0].attributes['href'].replaceAll('...', '');
    }
  } catch (error) {}
  return icon;
}

ThunkAction<AppState> fetchHomeserverIcons() {
  return (Store<AppState> store) async {
    var homeservers = store.state.matrixStore.homeservers;
    print(homeservers.runtimeType);

    homeservers.forEach((homeserver) async {
      var iconUrl = await fetchHomeserverIcon(homeserver: homeserver);
      homeserver['iconUrl'] = iconUrl;

      print(homeserver['iconUrl']);
    });
  };
}

ThunkAction<AppState> fetchHomeservers() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));
    var response = await http.get(HOMESERVER_SEARCH_SERVICE);
    var homeservers = json.decode(response.body);

    store.dispatch(SetHomeservers(homeservers: homeservers));
    store.dispatch(SetLoading(loading: false));
    store.dispatch(fetchHomeserverIcons());
  };
}

ThunkAction<AppState> searchHomeservers({String searchText}) {
  return (Store<AppState> store) async {
    List<dynamic> searchResults = store.state.userStore.homeservers
        .where((homeserver) =>
            homeserver['hostname'].contains(searchText) ||
            homeserver['description'].contains(searchText))
        .toList();
    store.dispatch(SetSearchResults(searchResults: searchResults));
  };
}
