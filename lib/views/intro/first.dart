import 'package:Tether/global/dimensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Tether/global/assets.dart';

class FirstSection extends StatelessWidget {
  FirstSection({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
            width: width * 0.7,
            height: DEFAULT_INPUT_HEIGHT,
            constraints: BoxConstraints(
              minWidth: 200,
              maxWidth: 400,
              minHeight: 200,
            ),
            child: SvgPicture.asset(
              HIDDEN_MESSENGER_GRAPHIC,
              semanticsLabel: 'User hidding behind a message',
            ),
          ),
          SizedBox(height: height * 0.05),
          Text(
            'Tether works by using an encrypted \nand decentralized protocol called Matrix',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.subtitle2,
          ),
        ],
      ),
    );
  }
}
