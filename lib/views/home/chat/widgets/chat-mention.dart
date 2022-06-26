import 'package:flutter/material.dart';
import 'package:syphon/store/user/model.dart';


class Mention extends StatefulWidget{

  const Mention({
    Key? key,
    required this.data
  }) : super(key: key);

  final List<User?> data;

  @override
  State<StatefulWidget> createState() => MentionState();
}

class MentionState extends State<Mention>{

  List<String> images = [
    "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg",
    "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg",
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (buildContext, index){
        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(images[index]

            ),),
            title: Text('This is title'),
            subtitle: Text('This is subtitle'),
          ),
        );
      },
      itemCount: images.length,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
    );
  }
}

