import 'package:flutter/material.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';

class Mention extends StatefulWidget {
  Mention(
      {Key? key,
      required this.users,
      required this.width,
      required this.controller,
      this.visible = false,
      this.height = 200})
      : super(key: key);

  final List<User> users;
  final double width;
  final double height;
  final TextEditingController controller;
  bool visible;

  @override
  State<StatefulWidget> createState() => MentionState();
}

class MentionState extends State<Mention> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: widget.height,
            maxWidth: widget.width
        ),
        child: ListView.builder(
          itemBuilder: (buildContext, index) {
            final String userName = formatUsername(widget.users[index]);
            return Visibility(
                visible: widget.visible,
                child: Card(
                  child: ListTile(
                    onTap: () => onTab(widget.users[index]),
                    leading: Avatar(
                      uri: widget.users[index].avatarUri,
                      alt: userName,
                      size: Dimensions.avatarSizeMin,
                      background: AppColors.hashedColor(
                        userName,
                      ),
                    ),
                    title: Text(userName),
                    subtitle: Text(widget.users[index].userId!),
                  ),
                ));
          },
          itemCount: widget.users.length,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          physics: ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 5),
        ));
  }

  onTab(User user) {
      final text = widget.controller.text;
      final cursorPos = widget.controller.selection.baseOffset;
      final subText = text.substring(0, cursorPos);

      final RegExp mentionExpEnd = RegExp(
        r'\B@\w+$',
        caseSensitive: false,
        multiLine: false,
      );

      widget.controller.text = subText.replaceAll(mentionExpEnd, '${user.userId} ') + text.substring(cursorPos);
      widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length)); // move cursor to end

      setState(() {
        widget.visible = false;
      });
  }
}
