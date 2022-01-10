import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_image_provider/device_image.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/views/widgets/lifecycle.dart';

_empty(File file) {}

///
/// Local Image List
///
/// Preview local device images for selection
///
class ListLocalImages extends StatefulWidget {
  const ListLocalImages({
    Key? key,
    this.imageSize = 128,
    this.onSelectImage = _empty,
  }) : super(key: key);

  final double imageSize;
  final Function(File imagefile) onSelectImage;

  @override
  _ListLocalImagesState createState() => _ListLocalImagesState();
}

class _ListLocalImagesState extends State<ListLocalImages> with Lifecycle<ListLocalImages> {
  List<LocalImage> images = [];
  LocalImageProvider imageProvider = LocalImageProvider();

  @override
  onMounted() async {
    final hasPermission = await imageProvider.initialize();
    if (hasPermission) {
      final latestMedia = await imageProvider.findLatest(10);

      // TODO: handle video previews
      final latestImages = latestMedia.where((media) => media.isImage).toList();

      setState(() {
        images = latestImages;
      });
    }
  }

  onSelected(LocalImage image) async {
    final imageBytes = await imageProvider.imageBytes(
      image.id!,
      image.pixelHeight!,
      image.pixelWidth!,
    );

    // NOTE: !!! default from imageProvider.imageBytes !!!
    const imageType = 'jpeg';
    final filename = '${image.id}.$imageType';

    final directory = await getTemporaryDirectory();
    final file = File(path.join(directory.path, filename));

    await file.writeAsBytes(imageBytes);

    widget.onSelectImage(file);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (images.isEmpty) {
      return Container(
          width: width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 8, top: 8),
                child: Icon(
                  Icons.search,
                  size: Dimensions.iconSize * 1.5,
                  color: const Color(Colours.greyDefault),
                ),
              ),
              Text(
                Strings.alertNoImagesFound,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.button?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ));
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: images.length,
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int index) {
        final image = images[index];

        if (image.isVideo) {
          // TODO: handle video previews here
        }

        ///
        /// Image Media Preview
        ///
        /// Example of clip / clipping edges of a stacked image
        /// as well as the image itself for proper ripple and image
        /// border radius
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
            ),
            width: widget.imageSize,
            height: widget.imageSize,
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  bottom: 0.0,
                  child: Material(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Image(
                        image: DeviceImage(image),
                        fit: BoxFit.cover,
                        width: widget.imageSize,
                        height: widget.imageSize,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelected(image),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
