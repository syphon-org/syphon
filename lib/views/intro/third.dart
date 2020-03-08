import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Tether/global/assets.dart';

class ThirdSection extends StatelessWidget {
  ThirdSection({Key key, this.title}) : super(key: key);

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
          width: width,
          constraints: BoxConstraints(
            maxHeight: 256,
            maxWidth: 320,
          ),
          child: SvgPicture.asset(
            WORKING_TOGETHER_GRAPHIC,
            semanticsLabel: 'People lounging around and messaging',
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxHeight: 88,
          ),
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Both Matrix and Tether are developed\nopenly by organizations and people,\nnot corporations.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ],
          ),
        )
      ],
    ));
  }
}
