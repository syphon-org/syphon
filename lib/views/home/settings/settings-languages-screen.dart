import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/dimensions.dart';

import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/views/widgets/appbars/appbar-normal.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(store),
        builder: (context, props) {
          return Scaffold(
            appBar: AppBarNormal(title: Strings.titleChatSettings),
            body: Center(
              child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: props.languagesAll.length,
                  itemBuilder: (BuildContext context, int index) {
                    final language = props.languagesAll[index];
                    final names = DisplayName.isoLangs[language]!;
                    final displayName = names['name'];
                    final nativeName = names['nativeName'];

                    return ListTile(
                      dense: true,
                      onTap: () => props.onSelectLanguage(language),
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        displayName ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                      subtitle: Text(
                        nativeName ?? 'N/A',
                        style: Theme.of(context).textTheme.caption,
                      ),
                      trailing: Visibility(
                        visible: props.language == language,
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),
            ),
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
        language: store.state.settingsStore.language,
        languagesAll: SupportedLanguages.all,
        onSelectLanguage: (String languageCode) {
          store.dispatch(setLanguage(languageCode));
          store.dispatch(addInfo(
            message: Strings.alertAppRestartEffect,
            action: 'Dismiss',
          ));
        },
      );
}
