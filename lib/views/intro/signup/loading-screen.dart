import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/svg.dart';
import 'package:syphon/global/colours.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import 'package:syphon/global/assets.dart';
import 'package:syphon/views/behaviors.dart';

class LoadingScreen extends StatelessWidget {
  final bool lite;

  const LoadingScreen({
    Key? key,
    this.lite = false,
  }) : super(key: key);

  buildLoadingDefault(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: ScrollConfiguration(
        behavior: DefaultScrollBehavior(),
        child: SingleChildScrollView(
          // Use a container of the same height and width
          // to flex dynamically but within a single child scroll
          child: Container(
            height: height,
            width: width,
            color: Color(Colours.whiteDefault),
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TouchableOpacity(
                  child: SvgPicture.asset(
                    Assets.appIcon,
                    width: width * 0.35,
                    height: width * 0.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  buildLoadingInverted(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: ScrollConfiguration(
        behavior: DefaultScrollBehavior(),
        child: SingleChildScrollView(
          // Use a container of the same height and width
          // to flex dynamically but within a single child scroll
          child: Container(
            height: height,
            width: width,
            color: Color(Colours.cyanSyphon),
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TouchableOpacity(
                  child: SvgPicture.asset(
                    Assets.appIconLite,
                    width: width * 0.35,
                    height: width * 0.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => lite
      ? buildLoadingInverted(
          context,
        )
      : buildLoadingDefault(
          context,
        );
}
