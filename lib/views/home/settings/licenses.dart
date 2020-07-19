import 'dart:io';

import 'package:syphon/global/values.dart';
import 'package:syphon/store/index.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

final String debug = DotEnv().env['DEBUG'];

class LicensesView extends StatelessWidget {
  LicensesView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        converter: (Store<AppState> store) => Props.mapStateToProps(store),
        builder: (context, props) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            body: Container(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: Values.openSourceLibraries.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context, int index) {
                  final library = Values.openSourceLibraries[index];
                  return ListTile();
                },
              ),
            ),
          );
        },
      );
}

class Props extends Equatable {
  Props();

  @override
  List<Object> get props => [];

  static Props mapStateToProps(
    Store<AppState> store,
  ) =>
      Props();
}
