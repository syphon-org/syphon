import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:syphon/global/strings.dart';

class AppBarNormal extends StatelessWidget implements PreferredSizeWidget {
  const AppBarNormal({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

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
      );

  @override
  Size get preferredSize => AppBar().preferredSize;
}
