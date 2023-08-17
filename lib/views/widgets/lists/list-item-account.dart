import 'package:flutter/material.dart';
import 'package:syphon/domain/user/model.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
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
/// TODO: rename because user specific, use this to wrap ListTile styling
///
class ListItemAccount extends StatelessWidget {
  const ListItemAccount({
    super.key,
    required this.user,
    this.type = ListItemUserType.Selectable,
    this.enabled = false,
    this.loading = false,
    this.selected = false,
    this.real = true,
    this.onPress,
    this.onPressAvatar,
  });

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
          splashColor: selected ? Theme.of(context).shadowColor : Colors.transparent,
          child: child,
        );
      default:
        return child;
    }
  }

  @override
  Widget build(BuildContext context) => Opacity(
      opacity: enabled || selected ? 1 : 0.7,
      child: ColoredBox(
          color: selected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
          child: ListTile(
            enabled: enabled,
            selected: selected,
            onTap: onPress != null && enabled ? () => onPress!() : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: Dimensions.paddingMin,
              horizontal: Dimensions.paddingContainer,
            ),
            leading: Avatar(
              uri: user.avatarUri,
              alt: user.displayName ?? user.userId,
              size: Dimensions.avatarSizeMin,
              background: AppColors.hashedColorUser(user),
            ),
            title: Text(
              user.userId!,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )));
}
