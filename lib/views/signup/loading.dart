// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_redux/flutter_redux.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

// Project imports:
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/behaviors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';

class Loading extends StatelessWidget {
  Loading({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: ScrollConfiguration(
        behavior: DefaultScrollBehavior(),
        child: SingleChildScrollView(
          // Use a container of the same height and width
          // to flex dynamically but within a single child scroll
          child: Container(
            height: height,
            width: width,
            child: StoreConnector<AppState, dynamic>(
              converter: (store) => () => store.dispatch(incrementTheme()),
              builder: (context, onIncrementTheme) => Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TouchableOpacity(
                    onTap: () {
                      onIncrementTheme();
                    },
                    child: const Image(
                      width: 100,
                      height: 100,
                      image: AssetImage(Assets.appIconPng),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
