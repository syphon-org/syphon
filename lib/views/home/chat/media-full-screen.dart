import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';

class MediaFullScreen extends StatelessWidget {
  final String title;
  final Uint8List bytes;

  const MediaFullScreen({
    Key? key,
    required this.title,
    required this.bytes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          onPressed: () => {
            Navigator.of(context).pop(),
          },
          icon: Icon(
            Icons.arrow_back_outlined,
          ),
        ),
      ),
      body: PhotoView(
        imageProvider: MemoryImage(bytes),
      ),
    );
  }
}
