import 'package:flutter/material.dart';

/// RoundedPopupMenu
/// Mostly an example for myself on how to override styling or other options on
/// existing components app wide
class RoundedPopupMenu<T> extends StatelessWidget {
  const RoundedPopupMenu({
    Key? key,
    this.icon,
    this.onSelected,
    required this.itemBuilder,
  }) : super(key: key);

  /// Called when the button is pressed to create the items to show in the menu.
  final Widget? icon;
  final PopupMenuItemSelected<T>? onSelected;
  final PopupMenuItemBuilder<T> itemBuilder;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
        onSelected: onSelected,
        icon: icon ?? Icon(Icons.more_vert, color: Colors.white),
        itemBuilder: itemBuilder,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      );
}
