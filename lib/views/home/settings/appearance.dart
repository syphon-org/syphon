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
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      onTap: () {
                        store.dispatch(incrementTheme());
                      },
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
