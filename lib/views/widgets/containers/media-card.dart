import 'package:flutter/material.dart';

import 'package:syphon/global/colors.dart';
import 'package:syphon/global/noop.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    this.text,
    this.icon = Icons.photo,
    this.onPress = noop,
    this.disabled = false,
  });

  final String? text;
  final IconData? icon;
  final Function onPress;
  final bool disabled;

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        elevation: 0.0,
        color: const Color(AppColors.greyDefault),
        child: InkWell(
          onTap: disabled ? null : () => onPress(),
          onLongPress: disabled ? null : () => onPress(),
          child: Container(
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Icon(
                    icon,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
                Text(
                  text ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                    fontSize: 13
                      ),
                ),
              ],
            ),
          ),
        ),
      );
}
