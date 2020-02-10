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
    final widthScale = width * 0.825;
    print(height * 0.05);
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
              HIDDEN_MESSENGER_GRAPHIC,
              semanticsLabel: 'User hidding behind a message',
              allowDrawingOutsideViewBox: false,
            ),
          ),
          Container(
            height: 88,
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tether works by using an encrypted \nand decentralized protocol called Matrix',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
