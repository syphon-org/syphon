import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Tether/global/assets.dart';

class LandingSection extends StatelessWidget {
  LandingSection({Key key, this.title}) : super(key: key);

  final String title;
  final double DEFAULT_INPUT_HEIGHT = 52;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        SizedBox(height: height * 0.05),
        Container(
          width: width * 0.7,
          height: DEFAULT_INPUT_HEIGHT,
          constraints:
              BoxConstraints(minWidth: 200, maxWidth: 400, minHeight: 200),
          child: SvgPicture.asset(MOBILE_USER_GRAPHIC,
              semanticsLabel: 'Relaxed, Lounging User'),
        ),
        SizedBox(height: height * 0.025),
        Text(
          'Welcome to Tether',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.display1,
        ),
        SizedBox(height: height * 0.025),
        Text(
          'Take back your privacy and freedom \nwithout the hassle',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.subtitle,
        ),
      ],
    ));
  }
}
