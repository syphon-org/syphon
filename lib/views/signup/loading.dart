import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Store
import 'package:Tether/store/index.dart';
import 'package:Tether/store/settings/actions.dart';

// Styling
import 'package:touchable_opacity/touchable_opacity.dart';
import 'package:Tether/global/behaviors.dart';

// Assets
import 'package:Tether/global/assets.dart';

class Loading extends StatelessWidget {
  Loading({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    /* 
     * TODO: convert to flexibles
    */
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
