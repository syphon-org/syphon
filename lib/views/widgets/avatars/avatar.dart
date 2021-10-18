import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/views/widgets/image-matrix.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    Key? key,
    this.uri,
    this.url,
    this.file,
    this.alt,
    this.size = Dimensions.avatarSizeMin,
    this.force = false,
    this.margin,
    this.padding,
    this.background,
    this.selected = false,
    this.rebuild = true,
  }) : super(key: key);

  final bool force;
  final bool selected;
  final bool rebuild;
  final String? uri;
  final String? url;
  final String? alt;
  final File? file;
  final double size;
  final Color? background;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final bool emptyAvi = uri == null && url == null;
          final Color backgroundColor = !emptyAvi ? Colors.transparent : Colors.grey;

          var borderRadius = BorderRadius.circular(size);

          if (props.avatarShape == AvatarShape.Square) {
            borderRadius = BorderRadius.circular(size / 3);
          }

          Widget avatarWidget = ClipRRect(
            borderRadius: borderRadius,
            child: Text(
              formatInitialsLong(alt ?? ''),
              style: TextStyle(
                color: Colors.white,
                fontSize: Dimensions.avatarFontSize(size: size),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.9,
              ),
            ),
          );

          if (url != null) {
            avatarWidget = ClipRRect(
              borderRadius: borderRadius,
              child: Image(
                image: NetworkImage(url!),
                width: size,
                height: size,
                fit: BoxFit.fill,
              ),
            );
          }

          if (uri != null) {
            avatarWidget = ClipRRect(
              borderRadius: borderRadius,
              child: MatrixImage(
                mxcUri: uri,
                width: size,
                height: size,
                fallbackColor: Colors.transparent,
                rebuild: false,
              ),
            );
          }

          if (file != null) {
            avatarWidget = ClipRRect(
              borderRadius: borderRadius,
              child: Image.file(
                file!,
                width: size,
                height: size,
                fit: BoxFit.cover,
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
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: emptyAvi && !force ? background ?? backgroundColor : Colors.transparent,
                  ),
                  child: Center(child: avatarWidget),
                ),
                Visibility(
                  visible: selected,
                  child: Positioned(
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          border: Border.all(
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(Dimensions.badgeAvatarSize),
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
        },
      );
}

class _Props extends Equatable {
  final AvatarShape avatarShape;

  const _Props({
    required this.avatarShape,
  });

  @override
  List<Object?> get props => [avatarShape];

  _Props.mapStateToProps(Store<AppState> store)
      : avatarShape = store.state.settingsStore.themeSettings.avatarShape;
}
