import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';

class MentionDialog extends HookWidget implements PreferredSizeWidget {
  const MentionDialog({
    required this.users,
    required this.width,
    required this.controller,
    required this.onComplete,
    this.visible = false,
    this.height = 200,
  });

  @override
  Size get preferredSize => AppBar().preferredSize;

  final List<User> users;
  final double width;
  final double height;
  final TextEditingController controller;
  final bool visible;

  final Function onComplete;

  onTab(User user) {
    final text = controller.text;
    final cursorPos = controller.selection.baseOffset;
    final subText = text.substring(0, cursorPos);

    final RegExp mentionExpEnd = RegExp(
      r'\B@\w+$',
      caseSensitive: false,
      multiLine: false,
    );

    controller.text = subText.replaceAll(mentionExpEnd, '${user.userId} ') + text.substring(cursorPos);

    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length), // move cursor to end
    );

    onComplete();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height, maxWidth: width),
      child: ListView.builder(
        itemBuilder: (buildContext, index) {
          final String userName = formatUsername(users[index]);

          return Visibility(
              visible: visible,
              child: Card(
                child: ListTile(
                  onTap: () => onTab(users[index]),
                  leading: Avatar(
                    uri: users[index].avatarUri,
                    alt: userName,
                    size: Dimensions.avatarSizeMin,
                    background: AppColors.hashedColor(
                      userName,
                    ),
                  ),
                  title: Text(userName),
                  subtitle: Text(users[index].userId!),
                ),
              ));
        },
        itemCount: users.length,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 5),
      ));
}
