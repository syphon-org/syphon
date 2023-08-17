import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

class ModalImageOptions extends StatelessWidget {
  const ModalImageOptions({
    super.key,
    this.onSetNewAvatar,
    this.onRemoveAvatar,
  });

  final Function? onSetNewAvatar;
  final Function? onRemoveAvatar;

  @override
  Widget build(BuildContext context) => Container(
        height: Dimensions.defaultModalHeight,
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
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
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.camera_alt,
                  size: 30,
                ),
              ),
              title: Text(
                Strings.listItemImageOptionsTakePhoto,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () async {
                final PickedFile? image = await ImagePicker().getImage(
                  source: ImageSource.camera,
                  maxWidth: Dimensions.avatarSizeMax,
                  maxHeight: Dimensions.avatarSizeMax,
                );

                if (image == null) return;

                final File imageFile = File(image.path);
                onSetNewAvatar?.call(image: imageFile);

                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.photo_library,
                  size: 28,
                ),
              ),
              title: Text(
                Strings.listItemImageOptionsPickFromGallery,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () async {
                final PickedFile? image = await ImagePicker().getImage(
                  source: ImageSource.gallery,
                  maxWidth: Dimensions.avatarSizeMax,
                  maxHeight: Dimensions.avatarSizeMax,
                );

                if (image == null) return;

                final File imageFile = File(image.path);

                onSetNewAvatar?.call(image: imageFile);
                Navigator.pop(context);
              },
            ),
            ListTile(
              onTap: () async {
                await onRemoveAvatar?.call();
                Navigator.pop(context);
              },
              leading: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.delete_forever,
                  size: 34,
                ),
              ),
              title: Text(
                Strings.listItemImageOptionsRemovePhoto,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      );
}
