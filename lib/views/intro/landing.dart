// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_svg/flutter_svg.dart';

// Project imports:
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

class LandingSection extends StatelessWidget {
  LandingSection({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    final widthScale = width * 0.8;
    final heightScale = height / 3;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
            width: widthScale,
            constraints: BoxConstraints(
              maxWidth: Dimensions.mediaSizeMax,
              maxHeight: height / 3,
            ),
            child: SvgPicture.asset(
              Assets.heroIntroMobileUser,
              semanticsLabel: Strings.semanticsLabelImageIntro,
            ),
          ),
          Flexible(
            flex: 0,
            child: Flex(
              mainAxisAlignment: MainAxisAlignment.center,
              direction: Axis.vertical,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    Strings.titleIntro,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headline4
                        .copyWith(fontSize: height < 569 ? 28 : null),
                  ),
                ),
              ],
            ),
          ),
          Container(
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Strings.subtitleIntro,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headline6
                      .copyWith(fontSize: height < 569 ? 18 : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
