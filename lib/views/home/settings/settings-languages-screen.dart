import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';

import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key)

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                Strings.titleChatSettings,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            body: SingleChildScrollView(
                child: Container(
              padding: EdgeInsets.only(bottom: 24),
            )),
          );
        },
      );
}

class Props extends Equatable {
  final String? language;

  final List<String> languagesAll;

  final Function onSelectLanguage;

  const Props({
    required this.language,
    required this.languagesAll,
    required this.onSelectLanguage,
  });

  @override
  List<Object?> get props => [
        language,
        languagesAll,
      ];

  static Props mapStateToProps(Store<AppState> store) => Props(
        language: DisplayName(Locale(store.state.settingsStore.language)).toDisplayName(),
        languagesAll: SupportedLanguages.all,
        onSelectLanguage: () {
          store.dispatch(incrementLanguage());
          store.dispatch(addInfo(
            message: Strings.alertAppRestartEffect,
            action: 'Dismiss',
          ));
        },
      );
}
