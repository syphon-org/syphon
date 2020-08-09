// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_svg/flutter_svg.dart';

// Project imports:
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

class FirstSection extends StatelessWidget {
  FirstSection({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final widthScale = width * 0.825;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
            width: widthScale,
            constraints: BoxConstraints(
              maxHeight: 256,
              maxWidth: 320,
            ),
            child: SvgPicture.asset(
              Assets.heroIntroHiddenMessage,
              semanticsLabel: 'User hidding behind a message',
            ),
          ),
          Container(
            height: 88,
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: Strings.contentIntroFirstPartOne,
                    style: Theme.of(context).textTheme.subtitle1,
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Matrix',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
