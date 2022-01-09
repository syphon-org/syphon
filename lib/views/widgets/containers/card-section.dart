import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';

class CardSection extends StatelessWidget {
  const CardSection({
    Key? key,
    this.child,
    this.margin,
    this.padding,
    this.elevation,
  }) : super(key: key);

  final Widget? child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? elevation;

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(store),
        builder: (context, props) {
          return Card(
            margin: margin ?? EdgeInsets.symmetric(vertical: 4),
            elevation: elevation ?? 0.5,
            // Re-use the System UI color because they are exactly the same
            color: Color(selectSystemUiColor(props.themeType)),
            child: Container(
              padding: padding ?? EdgeInsets.only(top: 12),
              child: child,
            ),
          );
        },
      );
}

class Props extends Equatable {
  final ThemeType themeType;

  const Props({
    required this.themeType,
  });

  @override
  List<Object> get props => [
        themeType,
      ];

  static Props mapStateToProps(Store<AppState> store) => Props(
        themeType: store.state.settingsStore.themeSettings.themeType,
      );
}
