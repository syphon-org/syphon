import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

const ICON_SIZE = 108.0;

class LoadingScreen extends StatelessWidget {
  final bool dark;

  const LoadingScreen({
    super.key,
    this.dark = false,
  });

  buildLoadingLight(BuildContext context) {
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
            color: Color(AppColors.whiteDefault),
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

  buildLoadingDark(BuildContext context) {
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
            color: Color(AppColors.cyanSyphon),
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TouchableOpacity(
                  child: SvgPicture.asset(
                    Assets.appIcon,
                    width: width * 0.35,
                    height: width * 0.35,
                    colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
  Widget build(BuildContext context) => dark ? buildLoadingDark(context) : buildLoadingLight(context);
}
