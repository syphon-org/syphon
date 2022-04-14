import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';


class MediaFullScreen extends StatelessWidget {
  final String title;
  final Uint8List bytes;
  final String? roomId;
  final String? eventId;

  const MediaFullScreen({
    Key? key,
    required this.roomId,
    required this.title,
    required this.bytes,
    required this.eventId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: Icon(Icons.download),
              color: Colors.white,
              onPressed:  () async {
               
              }
          ),
          IconButton(icon: Icon(Icons.share),
              color: Colors.white,
              onPressed: () async {
                await Share.share('https://matrix.to/#/$roomId/$eventId');
              }
          ),
        ],
        title: Text(
            title,
            style: TextStyle(
              color: Colors.white,)
        ),
        leading: IconButton(
          onPressed: () => {
            Navigator.of(context).pop(),
          },
          icon: Icon(Icons.arrow_back_outlined,),
          color: Colors.white,
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
