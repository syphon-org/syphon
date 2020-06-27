import 'package:syphon/global/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Assets
import 'package:syphon/global/assets.dart';

class SecondSection extends StatelessWidget {
  SecondSection({Key key, this.title}) : super(key: key);

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
            Assets.heroIntroConnection,
            semanticsLabel: 'Two people messaging privately but leisurely',
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
                  text: Strings.contentIntroSecondPartOne,
                  style: Theme.of(context).textTheme.subtitle1,
                  children: <TextSpan>[
                    TextSpan(
                      text: Strings.contentIntroSecondPartBold,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: Strings.contentIntroSecondPartTwo,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    ));
  }
}
