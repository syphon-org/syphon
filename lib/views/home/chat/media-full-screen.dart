import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';

import 'package:syphon/store/settings/theme-settings/selectors.dart';


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
              color: computeContrastColorText(
                Theme.of(context).appBarTheme.backgroundColor,
              ),
              onPressed:  () async {
                  final store = StoreProvider.of<AppState>(context);
                  store.dispatch(addInfo(message: Strings.alertFeatureInProgress));
              }
          ),
          IconButton(icon: Icon(Icons.share),
              color: computeContrastColorText(
                Theme.of(context).appBarTheme.backgroundColor,
              ),
              onPressed: () async {
                await Share.share(MatrixApi.fetchMessageUrl(roomId: roomId,eventId: eventId));
              }
          ),
        ],
        title: Text(
            title,
            style: TextStyle(
              color: computeContrastColorText(
                Theme.of(context).appBarTheme.backgroundColor,
              ),)
        ),
        leading: IconButton(
          onPressed: () => {
            Navigator.of(context).pop(),
          },
          icon: Icon(Icons.arrow_back_outlined,),
          color: computeContrastColorText(
            Theme.of(context).appBarTheme.backgroundColor,
          ),
        ),
      ),
      body: PhotoView(
        // Allow zooming in up to double the image size
        // anything beyond is usually pointless as the image becomes too pixelated
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        imageProvider: MemoryImage(bytes),
      ),
    );
  }
}
