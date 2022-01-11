import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:syphon/global/assets.dart';
import 'package:syphon/global/strings.dart';

class ThirdDescriptionPage extends StatelessWidget {
  const ThirdDescriptionPage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    final widthScale = width * 0.8;
    final heightScale = height / 2.5;

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(bottom: 16),
          constraints: BoxConstraints(
            maxWidth: widthScale,
            maxHeight: heightScale,
          ),
          child: SvgPicture.asset(
            Assets.heroIntroGroupChat,
            semanticsLabel: Strings.semanticsIntroThird,
          ),
        ),
        Flexible(
          flex: 0,
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Strings.contentIntroThird,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ],
          ),
        ),
      ],
    ));
  }
}
