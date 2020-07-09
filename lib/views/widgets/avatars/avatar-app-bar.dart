import 'package:syphon/global/dimensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/image-matrix.dart';

class AvatarAppBar extends StatelessWidget {
  AvatarAppBar({
    Key key,
    this.user,
    this.loading = false,
    this.syncing = false,
    this.offline = false,
    this.tooltip,
    this.onPressed,
  }) : super(key: key);

  final User user;
  final bool loading;
  final bool syncing;
  final bool offline;
  final String tooltip;
  final Function onPressed;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(right: 8),
        child: Stack(
          children: <Widget>[
            IconButton(
              padding: EdgeInsets.all(4),
              icon: CircleAvatar(
                backgroundColor: Colors.grey,
                child: user.avatarUri != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Dimensions.thumbnailSizeMax,
                        ),
                        child: MatrixImage(
                          mxcUri: user.avatarUri,
                          thumbnail: true,
                        ),
                      )
                    : Text(
                        displayInitials(user),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
              ),
              onPressed: onPressed,
              tooltip: tooltip,
            ),
            Visibility(
              visible: offline,
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
                    color: Colors.blueGrey,
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
                    color: Theme.of(context).scaffoldBackgroundColor,
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
