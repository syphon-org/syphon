import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Tether/global/assets.dart';

class ActionSection extends StatelessWidget {
  ActionSection({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final widthScale = width * 0.8;

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
            Assets.heroIntroPeople,
            semanticsLabel: Strings.semanticsIntroFinal,
          ),
        ),
        Container(
          height: 88,
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Strings.contentIntroFinal,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ],
          ),
        )
      ],
    ));
  }
}
