import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/strings.dart';
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
    final widthScale = width * 0.825;
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Container(
          width: widthScale,
          constraints: BoxConstraints(
            maxHeight: 253,
            maxWidth: 320,
          ),
          child: SvgPicture.asset(
            MOBILE_USER_GRAPHIC,
            semanticsLabel: Strings.semanticsLabelImageIntro,
          ),
        ),
        Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Text(
            Strings.titleIntro,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline4,
          ),
        ),
        FittedBox(
          fit: BoxFit.fitWidth,
          child: Text(
            Strings.subtitleIntro,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
      ],
    ));
  }
}
