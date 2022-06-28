import 'package:flutter/material.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';


class Mention extends StatefulWidget{

  const Mention({
    Key? key,
    required this.users
  }) : super(key: key);

  final List<dynamic> users;

  @override
  State<StatefulWidget> createState() => MentionState();
}

class MentionState extends State<Mention>{


  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 200.0,
        ),
        child: ListView.builder(itemBuilder: (buildContext, index){
          final String userName = formatUsername(widget.users[index] as User);
          return Card(
            child: ListTile(
              leading: Avatar(
                  uri: widget.users[index]?.avatarUri,
                  alt:  userName,
                  size: Dimensions.avatarSizeMin,
                  background: AppColors.hashedColor(
                    userName,
                  ),),
              title: Text(userName),
              subtitle: Text(widget.users[index]?.userId),
            ),
          );
        },
        itemCount: widget.users.length,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 5),
    ));
  }
}

