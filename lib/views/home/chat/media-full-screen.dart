import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';

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
        actions: [
          IconButton(onPressed: () => {

            }, icon: Icon(Icons.download)),
          IconButton(onPressed: () => {

            }, icon: Icon(Icons.share)),
          IconButton(onPressed: () => {

            }, icon: Icon(Icons.open_in_browser)),
        ],
        title: Column(children: [

          Text('View embed', style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(
              color: Colors.white,
              fontSize: 10
          )),
        ]),
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
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        imageProvider: MemoryImage(bytes),
      ),
    );
  }
}
