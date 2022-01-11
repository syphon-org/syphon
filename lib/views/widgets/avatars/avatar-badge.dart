import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';

class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    Key? key,
    this.public = false,
    this.group = false,
    this.invite = false,
    this.encryptionEnabled = false,
  }) : super(key: key);

  final bool public;
  final bool group;
  final bool invite;
  final bool encryptionEnabled;

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          if (encryptionEnabled) {
            return Positioned(
              bottom: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  Dimensions.badgeAvatarSize,
                ),
                child: Container(
                  width: Dimensions.badgeAvatarSize,
                  height: Dimensions.badgeAvatarSize,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Icon(
                    Icons.lock_open,
                    color: Theme.of(context).iconTheme.color,
                    size: Dimensions.iconSizeMini,
                  ),
                ),
              ),
            );
          }

          if (invite) {
            return Positioned(
              bottom: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: Dimensions.badgeAvatarSize,
                  height: Dimensions.badgeAvatarSize,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Icon(
                    Icons.mail_outline,
                    color: Theme.of(context).iconTheme.color,
                    size: Dimensions.iconSizeMini,
                  ),
                ),
              ),
            );
          }

          if (group) {
            return Positioned(
              bottom: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: Dimensions.badgeAvatarSize,
                  height: Dimensions.badgeAvatarSize,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Icon(
                    Icons.group,
                    color: Theme.of(context).iconTheme.color,
                    size: Dimensions.badgeAvatarSizeSmall,
                  ),
                ),
              ),
            );
          }

          if (public) {
            return Positioned(
              bottom: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: Dimensions.badgeAvatarSize,
                  height: Dimensions.badgeAvatarSize,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Icon(
                    Icons.public,
                    color: Theme.of(context).iconTheme.color,
                    size: Dimensions.badgeAvatarSize,
                  ),
                ),
              ),
            );
          }

          return Container();
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
