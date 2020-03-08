import 'package:Tether/global/dimensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Tether/global/assets.dart';

class LandingSection extends StatelessWidget {
  LandingSection({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    final widthScale = width * 0.825;
    // TODO: convert to flex
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
            MOBILE_USER_GRAPHIC,
            semanticsLabel: 'Relaxed, Lounging User',
          ),
        ),
        Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Text(
            'Welcome to Tether',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline4,
          ),
        ),
        Text(
          'Take back your privacy and freedom \nwithout the hassle',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.subtitle2,
        ),
      ],
    ));
  }
}
