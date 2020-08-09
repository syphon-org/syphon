// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syphon/global/assets.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/image-matrix.dart';

class AvatarCircle extends StatelessWidget {
  AvatarCircle({
    Key key,
    this.uri,
    this.url,
    this.alt,
    this.size = 40,
    this.force = false,
    this.margin,
    this.padding,
    this.background,
    this.selected = false,
  }) : super(key: key);

  final bool force;
  final bool selected;
  final String uri;
  final String url;
  final String alt;
  final double size;
  final Color background;
  final EdgeInsets margin;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor =
        uri != null || url != null ? Colors.transparent : Colors.grey;

    dynamic avatarWidget = Text(
      formatInitials(alt),
      style: TextStyle(
        color: Colors.white,
        fontSize: Dimensions.avatarFontSize(size: size),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.9,
      ),
    );

    if (url != null) {
      avatarWidget = ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: Image(
          image: NetworkImage(url),
          width: size,
          height: size,
          fit: BoxFit.fill,
        ),
      );
    }

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
      child: Stack(
        children: [
          CircleAvatar(
            radius: size / 2,
            child: avatarWidget,
            backgroundColor: uri == null && url == null && !force
                ? background ?? backgroundColor
                : Colors.transparent,
          ),
          Visibility(
            visible: selected,
            child: Positioned(
              right: 0,
              bottom: 0,
              child: ClipRRect(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).accentColor,
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                    borderRadius:
                        BorderRadius.circular(Dimensions.badgeAvatarSize),
                  ),
                  width: Dimensions.badgeAvatarSize,
                  height: Dimensions.badgeAvatarSize,
                  margin: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.check,
                    size: Dimensions.iconSizeMini,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
