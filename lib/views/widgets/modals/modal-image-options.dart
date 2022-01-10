import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

class ModalImageOptions extends StatelessWidget {
  const ModalImageOptions({
    Key? key,
    this.onSetNewAvatar,
  }) : super(key: key);

  final Function? onSetNewAvatar;

  @override
  Widget build(BuildContext context) => Container(
        height: Dimensions.defaultModalHeight,
        padding: EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 24,
              ),
              child: Text(
                Strings.listItemImageOptionsPhotoSelectMethod,
                textAlign: TextAlign.start,
              ),
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.camera_alt,
                  size: 30,
                ),
              ),
              title: Text(
                Strings.listItemImageOptionsTakePhoto,
                style: Theme.of(context).textTheme.subtitle1,
              ),
              onTap: () async {
                final PickedFile? image = await ImagePicker().getImage(
                  source: ImageSource.camera,
                  maxWidth: Dimensions.avatarSizeMax,
                  maxHeight: Dimensions.avatarSizeMax,
                );

                if (image == null) return;

                final File imageFile = File(image.path);
                if (onSetNewAvatar != null) {
                  onSetNewAvatar!(image: imageFile);
                }

                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.photo_library,
                  size: 28,
                ),
              ),
              title: Text(
                Strings.listItemImageOptionsPickFromGallery,
                style: Theme.of(context).textTheme.subtitle1,
              ),
              onTap: () async {
                final PickedFile? image = await ImagePicker().getImage(
                  source: ImageSource.gallery,
                  maxWidth: Dimensions.avatarSizeMax,
                  maxHeight: Dimensions.avatarSizeMax,
                );

                if (image == null) return;

                final File imageFile = File(image.path);

                if (onSetNewAvatar != null) {
                  onSetNewAvatar!(image: imageFile);
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              onTap: () => Navigator.pop(context),
              enabled: false,
              leading: Container(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_forever,
                  size: 34,
                ),
              ),
              title: Text(
                Strings.listItemImageOptionsRemovePhoto,
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ],
        ),
      );
}
