import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutterclient/ui/video_screen.dart';

List<CameraDescription> cameras;

Future<void> initCameras() async {
  cameras = await availableCameras();
}

class CreateTab extends StatefulWidget {
  @override
  _CreateTabState createState() => _CreateTabState();
}

class _CreateTabState extends State<CreateTab> {
  CameraController _cameraController;

  @override
  void initState() {
    super.initState();
    initCameras().then((_) {
      _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      _cameraController.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController.value.isInitialized) {
      return Container(
        alignment: Alignment.center,
        child: Text("Camera Error")
      );
    } else
      return fullscreenAspectRatio(
        context: context,
        aspectRatio: _cameraController.value.aspectRatio,
        video: (width, height) {
          return Container(
            width: width,
            height: height,
            child: CameraPreview(_cameraController)
          );
        },
        stack: <Widget>[
          Text("Hello :)")
        ]
      );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}