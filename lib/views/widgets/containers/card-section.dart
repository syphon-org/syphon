import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/index.dart';

class CardSection extends StatelessWidget {
  CardSection({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(store),
        builder: (context, props) {
          var backgroundColor = Color(Colours.whiteDefault);

          switch (props.type) {
            case ThemeType.DARK:
              backgroundColor = Color(Colours.blackDefault);
              break;
            case ThemeType.DARKER:
              backgroundColor = Color(Colours.blackDefault);
              break;
            case ThemeType.NIGHT:
              backgroundColor = Color(Colours.blackFull);
              break;
            case ThemeType.LIGHT:
              backgroundColor = Color(Colours.whiteDefault);
              break;
            default:
              break;
          }

          return Card(
            margin: EdgeInsets.symmetric(vertical: 4),
            elevation: 0.5,
            color: backgroundColor,
            child: Container(
              padding: EdgeInsets.only(top: 12),
              child: child,
            ),
          );
        },
      );
}

class Props extends Equatable {
  final ThemeType type;

  Props({
    @required this.type,
  });

  @override
  List<Object> get props => [
        type,
      ];

  static Props mapStateToProps(Store<AppState> store) => Props(
        type: store.state.settingsStore.theme,
      );
}
