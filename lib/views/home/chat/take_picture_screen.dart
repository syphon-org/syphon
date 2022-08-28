import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:syphon/global/libs/matrix/constants.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera, required this.onAddMedia,
  });

  final CameraDescription camera;
  final Function({
  required File file,
  required MessageType type,
  }) onAddMedia;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    // initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Container(
            color: Colors.black,
            width: double.infinity,
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    takePicture();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                    primary: Colors.blue, // <-- Button color
                    onPrimary: Colors.red, // <-- Splash color
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                    primary: Colors.blue, // <-- Button color
                    onPrimary: Colors.red, // <-- Splash color
                  ),
                  child: Icon(Icons.menu, color: Colors.white),
                )
              ],
            ),
          )
        ],
      ),

    );
  }

  Future<void> takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;

      _controller.dispose();

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(
            imagePath: image.path,
            onAddMedia: widget.onAddMedia,
          ),
        ),
      );

    } catch (e) {
      print(e);
    }
  }

}



class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final Function({
  required File file,
  required MessageType type,
  }) onAddMedia;

  const DisplayPictureScreen({super.key, required this.imagePath, required this.onAddMedia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Image.file(File(imagePath)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await onAddPhoto();
          Navigator.pop(context);
        },
        child: Icon(Icons.send),
      ),
    );
  }

   Future<void> onAddPhoto() async {

    final file = File(imagePath);
    await onAddMedia(file: file, type: MessageType.image);

  }

}
