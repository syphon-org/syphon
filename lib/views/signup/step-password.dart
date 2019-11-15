import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Tether/global/assets.dart';

class PasswordStep extends StatelessWidget {
  PasswordStep({Key key}) : super(key: key);

  final double DEFAULT_INPUT_HEIGHT = 52;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: height * 0.1),
        Container(
          width: width * 0.7,
          height: DEFAULT_INPUT_HEIGHT,
          constraints:
              BoxConstraints(minWidth: 200, maxWidth: 400, minHeight: 240),
          child: SvgPicture.asset(SIGNUP_PASSWORD_GRAPHIC,
              semanticsLabel: 'User hidding behind a message'),
        ),
        SizedBox(height: 16),
        Text(
          'Create a password',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline,
        ),
        SizedBox(height: height * 0.025),
      ],
    ));
  }
}
