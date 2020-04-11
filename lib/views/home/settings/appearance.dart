import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/settings/actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class ApperanceScreen extends StatelessWidget {
  ApperanceScreen({Key key, this.title}) : super(key: key);

  final String title;

  displayThemeType(String themeTypeName) {
    return themeTypeName.split('.')[1].toLowerCase();
  }

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, Store<AppState>>(
        converter: (Store<AppState> store) => store,
        builder: (context, store) {
          double width = MediaQuery.of(context).size.width;
          double height = MediaQuery.of(context).size.height;

          // Static horizontal: 16, vertical: 8
          final contentPadding = EdgeInsets.symmetric(
            horizontal: width * 0.08,
            vertical: height * 0.005,
          );

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(title,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w100)),
            ),
            body: Container(
                child: Column(
              children: <Widget>[
                ListTile(
                  onTap: () {
                    store.dispatch(incrementTheme());
                  },
                  contentPadding: contentPadding,
                  title: Text(
                    'Theme',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  trailing: Text(
                    displayThemeType(
                      store.state.settingsStore.theme.toString(),
                    ),
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                ListTile(
                  onTap: () {},
                  contentPadding: contentPadding,
                  title: Text(
                    'Primary Color',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  trailing: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(
                      store.state.settingsStore.primaryColor,
                    ),
                  ),
                ),
                ListTile(
                  onTap: () {},
                  contentPadding: contentPadding,
                  title: Text(
                    'Accent Color',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  trailing: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(
                      store.state.settingsStore.accentColor,
                    ),
                  ),
                ),
                ListTile(
                  onTap: () {},
                  contentPadding: contentPadding,
                  title: Text(
                    'Language',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  trailing: Text(
                    store.state.settingsStore.language,
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ],
            )),
          );
        },
      );
}
