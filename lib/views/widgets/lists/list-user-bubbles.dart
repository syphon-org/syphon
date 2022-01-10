import 'package:flutter/material.dart';

import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/home/chat/chat-detail-all-users-screen.dart';
import 'package:syphon/views/home/groups/invite-users-screen.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

///
/// List of Users (Avi Bubbles)
///
/// Still uses userId because users
/// are still indexed by room
class ListUserBubbles extends StatelessWidget {
  const ListUserBubbles({
    Key? key,
    this.users = const [],
    this.roomId = '',
    this.invite = false,
    this.forceOption = false,
    this.max = 12,
  }) : super(key: key);

  final int max;
  final bool invite;
  final bool forceOption;
  final String? roomId;
  final List<User?> users;

  onShowUserDetails({
    required BuildContext context,
    User? user,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        user: user,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: users.length < max ? users.length : max,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              final user = users[index] ?? User();

              return Align(
                child: GestureDetector(
                  onTap: () {
                    onShowUserDetails(
                      context: context,
                      user: user,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 12 : 4,
                      right: index == users.length ? 12 : 4,
                    ),
                    child: Avatar(
                      uri: user.avatarUri,
                      alt: user.displayName ?? user.userId,
                      size: Dimensions.avatarSize,
                      background: Colours.hashedColorUser(user),
                    ),
                  ),
                ),
              );
            },
          ),
          Visibility(
            visible: users.length > max || forceOption,
            child: Container(
              margin: EdgeInsets.only(left: 4, right: 12),
              padding: EdgeInsets.symmetric(vertical: 14),
              child: ClipOval(
                child: Material(
                  color: Theme.of(context).scaffoldBackgroundColor, // button color
                  child: InkWell(
                    onTap: () {
                      if (invite) {
                        Navigator.pushNamed(
                          context,
                          Routes.userInvite,
                          arguments: InviteUsersArguments(roomId: null),
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          Routes.chatUsers,
                          arguments: ChatUsersDetailArguments(roomId: roomId),
                        );
                      }
                    },
                    splashColor: Colors.grey, // inkwell color
                    child: SizedBox(
                      width: Dimensions.avatarSize,
                      height: Dimensions.avatarSize,
                      child: Container(
                        width: Dimensions.avatarSize,
                        height: Dimensions.avatarSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(Dimensions.avatarSize),
                          ),
                          border: Border.all(
                            width: 4,
                            color: Theme.of(context).textTheme.caption!.color!,
                          ),
                        ),
                        child: Icon(
                          invite ? Icons.edit : Icons.arrow_forward_ios,
                          size: invite ? Dimensions.iconSize : Dimensions.iconSizeLarge,
                          color: Theme.of(context).textTheme.caption!.color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
