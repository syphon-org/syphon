import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syphon/global/assets.dart';

import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';

import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';

enum ListItemUserType {
  Selectable,
  Pressable,
}

///
/// List Item
///
/// Still uses userId because users
/// are still indexed by room
///
class ListItemUser extends StatelessWidget {
  const ListItemUser({
    Key? key,
    required this.user,
    this.type = ListItemUserType.Pressable,
    this.enabled = false,
    this.loading = false,
    this.selected = false,
    this.real = true,
    this.onPress,
    this.onPressAvatar,
  }) : super(key: key);

  final User user;
  final bool loading;
  final bool enabled;
  final bool selected;
  final ListItemUserType type;
  final bool real;
  final Function? onPress;
  final Function? onPressAvatar;

  Widget buildArrowIcon(context) => Semantics(
      button: true,
      enabled: true,
      label: 'Start Chat',
      child: ClipOval(
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor, // button color
          child: InkWell(
            onTap: onPress != null ? () => onPress!() : null,
            child: SizedBox(
              width: Dimensions.avatarSizeMin,
              height: Dimensions.avatarSizeMin,
              child: Container(
                width: Dimensions.iconSizeLite,
                height: Dimensions.iconSizeLite,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(Dimensions.avatarSize),
                  ),
                ),
                child: SvgPicture.asset(
                  Assets.iconSendBeing,
                  fit: BoxFit.scaleDown,
                  height: Dimensions.iconSizeLite,
                  width: Dimensions.iconSizeLite,
                  color: Theme.of(context).iconTheme.color,
                  semanticsLabel: 'Start Chat',
                ),
              ),
            ),
          ),
        ),
      ));

  Widget buildTouchType({required Widget child}) {
    switch (type) {
      case ListItemUserType.Pressable:
        return GestureDetector(
          onTap: onPress != null ? () => onPress!() : null,
          child: child,
        );
      case ListItemUserType.Selectable:
        return InkWell(
          onTap: onPress != null ? () => onPress!() : null,
          child: child,
        );
      default:
        return child;
    }
  }

  @override
  Widget build(BuildContext context) => CardSection(
        padding: EdgeInsets.zero,
        elevation: 0,
        child: buildTouchType(
          child: ListTile(
            enabled: enabled,
            tileColor: Theme.of(context).scaffoldBackgroundColor,
            leading: GestureDetector(
              onTap: onPressAvatar != null ? () => onPressAvatar!() : null,
              child: Stack(
                children: [
                  Avatar(
                    uri: user.avatarUri,
                    alt: user.displayName ?? user.userId,
                    selected: selected,
                    size: Dimensions.avatarSizeMin,
                    background: !real ? null : Colours.hashedColor(formatUsername(user)),
                  ),
                ],
              ),
            ),
            title: Text(
              formatUsername(user),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyText1,
            ),
            subtitle: Text(
              user.userId!,
              style: Theme.of(context).textTheme.caption!.merge(
                    TextStyle(
                      color: loading ? Color(Colours.greyDisabled) : null,
                    ),
                  ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: type == ListItemUserType.Pressable ? [buildArrowIcon(context)] : [],
            ),
          ),
        ),
      );
}
