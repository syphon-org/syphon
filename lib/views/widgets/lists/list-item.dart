import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';

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
class ListItem extends StatelessWidget {
  const ListItem({
    Key? key,
    required this.user,
    this.type = ListItemUserType.Selectable,
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

  Widget buildTouchType({required BuildContext context, required Widget child}) {
    switch (type) {
      case ListItemUserType.Pressable:
        return GestureDetector(
          onTap: onPress != null && enabled ? () => onPress!() : null,
          child: child,
        );
      case ListItemUserType.Selectable:
        return InkWell(
          splashColor: selected ? Theme.of(context).selectedRowColor : Colors.transparent,
          child: child,
        );
      default:
        return child;
    }
  }

  @override
  Widget build(BuildContext context) => Opacity(
      opacity: enabled ? 1 : 0.7,
      child: Container(
          color: selected ? Theme.of(context).selectedRowColor : Colors.transparent,
          child: ListTile(
            enabled: enabled,
            selected: selected,
            onTap: onPress != null && enabled ? () => onPress!() : null,
            contentPadding: EdgeInsets.symmetric(
              vertical: Dimensions.paddingMin,
              horizontal: Dimensions.paddingContainer,
            ),
            leading: Avatar(
              uri: user.avatarUri,
              alt: user.displayName ?? user.userId,
              size: Dimensions.avatarSizeMin,
              background: Colours.hashedColorUser(user),
            ),
            title: Text(
              user.userId!,
              overflow: TextOverflow.ellipsis,
              style: !selected
                  ? Theme.of(context).textTheme.bodyText2
                  : Theme.of(context).textTheme.bodyText2?.copyWith(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).textTheme.bodyText2?.color
                            : Colors.black,
                      ),
            ),
          )));
}
