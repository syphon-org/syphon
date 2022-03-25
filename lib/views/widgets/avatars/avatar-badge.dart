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
    this.indicator = false,
    this.unencrypted = false,
  }) : super(key: key);

  final bool public;
  final bool group;
  final bool invite;
  final bool indicator;
  final bool unencrypted;

  Widget buildIndicator(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          Dimensions.badgeAvatarSize,
        ),
        child: Container(
          width: Dimensions.badgeAvatarSizeSmall,
          height: Dimensions.badgeAvatarSizeSmall,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget buildBadge(BuildContext context, Icon icon, {Color? color}) {
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
          color: color ?? Theme.of(context).scaffoldBackgroundColor,
          child: icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          if (indicator) {
            return buildIndicator(context);
          }

          if (unencrypted) {
            return buildBadge(
              context,
              Icon(
                Icons.lock_open,
                color: Theme.of(context).iconTheme.color,
                size: Dimensions.iconSizeMini,
              ),
            );
          }

          if (invite) {
            return buildBadge(
              context,
              Icon(
                Icons.mail_outline,
                color: Theme.of(context).iconTheme.color,
                size: Dimensions.iconSizeMini,
              ),
            );
          }

          if (group) {
            return buildBadge(
              context,
              Icon(
                Icons.group,
                color: Theme.of(context).iconTheme.color,
                size: Dimensions.badgeAvatarSizeSmall,
              ),
            );
          }

          if (public) {
            return buildBadge(
              context,
              Icon(
                Icons.public,
                color: Theme.of(context).iconTheme.color,
                size: Dimensions.badgeAvatarSize,
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
