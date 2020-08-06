// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/image-matrix.dart';

class AvatarCircle extends StatelessWidget {
  AvatarCircle({
    Key key,
    this.uri,
    this.alt,
    this.size = 40,
    this.force = false,
    this.margin,
    this.padding,
    this.background,
  }) : super(key: key);

  final bool force;
  final String uri;
  final String alt;
  final double size;
  final Color background;
  final EdgeInsets margin;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = uri != null ? Colors.transparent : Colors.grey;

    dynamic avatarWidget = Text(
      formatInitials(alt),
      style: TextStyle(
        color: Colors.white,
        fontSize: Dimensions.avatarFontSize(size: size),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.9,
      ),
    );

    if (uri != null) {
      avatarWidget = ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: MatrixImage(
          mxcUri: uri,
          width: size,
          height: size,
          fit: BoxFit.fill,
          fallbackColor: Colors.transparent,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      margin: margin,
      padding: padding,
      color: Colors.transparent,
      child: CircleAvatar(
        radius: size / 2,
        child: avatarWidget,
        backgroundColor: uri == null && !force
            ? background ?? backgroundColor
            : Colors.transparent,
      ),
    );
  }
}
