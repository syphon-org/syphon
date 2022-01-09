import 'package:flutter/material.dart';

import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';

_empty() {}

class MediaCard extends StatelessWidget {
  const MediaCard({
    Key? key,
    this.text,
    this.icon = Icons.photo,
    this.onPress = _empty,
    this.disabled = false,
  }) : super(key: key);

  final String? text;
  final IconData? icon;
  final Function onPress;
  final bool disabled;

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        elevation: 0.0,
        color: const Color(Colours.greyDefault),
        child: InkWell(
          onTap: disabled ? null : () => onPress(),
          onLongPress: disabled ? null : () => onPress(),
          child: Container(
            width: 76,
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(bottom: 8, top: 8),
                  child: Icon(
                    icon,
                    size: 39,
                    color: Colors.white,
                  ),
                ),
                Text(
                  text ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.button?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
}
