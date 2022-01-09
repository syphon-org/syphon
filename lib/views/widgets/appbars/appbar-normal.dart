import 'package:flutter/material.dart';

import 'package:syphon/global/strings.dart';

class AppBarNormal extends StatelessWidget implements PreferredSizeWidget {
  const AppBarNormal({
    Key? key,
    required this.title,
    this.actions,
  }) : super(key: key);

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
          tooltip: Strings.labelBack.capitalize(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w100,
          ),
        ),
        actions: actions ?? const [],
      );

  @override
  Size get preferredSize => AppBar().preferredSize;
}
