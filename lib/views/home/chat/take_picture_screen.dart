import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:syphon/global/libs/matrix/constants.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.cameras, required this.onAddMedia,
  });

  // final CameraDescription camera;
  // final CameraDescription secondaryCamera;
  final List<CameraDescription> cameras;

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
      widget.cameras.first,
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
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: (){
                      takePicture();
                    },
                    child: Container(
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(width: 2, color: Colors.white),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: FractionallySizedBox(
                          heightFactor: 0.9, // Adjust those two for the white space
                          widthFactor: 0.9,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(width: 2, color: Colors.white),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.flip_camera_android_rounded, color: Colors.white),
                      onPressed: (){
                        _toggleCameraLens();
                      },
                    ),
                  )

                ],
              ),
            ),
          )
        ],
      ),

    );
  }

  void _toggleCameraLens() {
    // get current lens direction (front / rear)
    final lensDirection = _controller.description.lensDirection;
    CameraDescription newDescription;
    if (lensDirection == CameraLensDirection.front) {
      newDescription = widget.cameras.firstWhere((description) => description
          .lensDirection == CameraLensDirection.back);
    }
    else {
      newDescription = widget.cameras.firstWhere((description) => description
          .lensDirection == CameraLensDirection.front);
    }

    if (newDescription != null) {
      _initCamera(newDescription);
    }
    else {
      print('Asked camera not available');
    }
  }

  Future<void> _initCamera(CameraDescription description) async{
    _controller = CameraController(description, ResolutionPreset.max, enableAudio: true);

    try{
      await _controller.initialize();
      // to notify the widgets that camera has been initialized and now camera preview can be done
      setState((){});
    }
    catch(e){
      print(e);
    }
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
