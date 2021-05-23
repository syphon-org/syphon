// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';

class AvatarAppBar extends StatelessWidget {
  AvatarAppBar({
    Key? key,
    this.user,
    this.theme = ThemeType.LIGHT,
    this.syncing = false,
    this.offline = false,
    this.unauthed = false,
    this.tooltip,
    this.onPressed,
  }) : super(key: key);

  final User? user;
  final bool syncing;
  final bool? offline;
  final bool unauthed;
  final String? tooltip;
  final ThemeType theme;

  final Function? onPressed;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(right: 8),
        child: Stack(
          children: <Widget>[
            IconButton(
              padding: EdgeInsets.all(4),
              icon: Avatar(
                uri: user!.avatarUri,
                alt: user!.displayName ?? user!.userId,
                background: Colors.grey,
              ),
              onPressed: onPressed as void Function()?,
              tooltip: tooltip,
            ),
            Visibility(
              visible: offline!,
              child: Positioned(
                bottom: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Dimensions.thumbnailSizeMax,
                  ),
                  child: Container(
                    height: 16,
                    width: 16,
                    color: Themes.backgroundBrightness(theme),
                    child: Icon(
                      Icons.offline_bolt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: unauthed,
              child: Positioned(
                bottom: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Dimensions.thumbnailSizeMax,
                  ),
                  child: Container(
                    height: 16,
                    width: 16,
                    color: Themes.backgroundBrightness(theme),
                    child: Icon(
                      Icons.block,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: syncing,
              child: Positioned(
                bottom: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Dimensions.thumbnailSizeMax,
                  ),
                  child: Container(
                    height: 16,
                    width: 16,
                    padding: EdgeInsets.all(2),
                    color: Themes.backgroundBrightness(theme),
                    child: CircularProgressIndicator(
                      strokeWidth: Dimensions.defaultStrokeWidthLite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
