import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutterclient/api/upload.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/ui/widget/video_screen.dart';
import 'package:image_picker/image_picker.dart';

List<CameraDescription> cameras;

Future<void> initCameras() async {
  cameras = await availableCameras();
}

class _UploadDetailsScreen extends StatefulWidget {
  final UploadableVideo builder;

  _UploadDetailsScreen(this.builder);

  @override
  _UploadDetailsScreenState createState() => _UploadDetailsScreenState();
}

class _UploadDetailsScreenState extends State<_UploadDetailsScreen> {
  TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                child: TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    hintText: "Video Description..",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                )
              ),
              BorderedFlatButton(
                onTap: () {
                  logger.i("Upload video save btn");
                },
                text: Text("Upload"),
                width: 150,
                height: 50,
                margin: EdgeInsets.all(5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateTab extends StatefulWidget {
  @override
  _CreateTabState createState() => _CreateTabState();
}

class _CreateTabState extends State<CreateTab> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (!loading)
            BorderedFlatButton(
              onTap: () async {
                var file = await ImagePicker().getVideo(
                  source: ImageSource.camera,
                  preferredCameraDevice: CameraDevice.front,
                  maxDuration: Duration(seconds: 60),
                );

                if (file == null) return;

                var builder = await requestUpload();
                if (builder == null) return;

                Navigator.of(context).push(
                  zoomTo((context, animation, secondaryAnimation) {
                    return _UploadDetailsScreen(builder);
                  }),
                );

                uploadVideo(builder, file).then((success) {
                  logger.i("Uploaded video: $success");
                }).catchError((error) {
                  logger.w("Upload failed: $error}");
                });
              },
              text: Text(
                "Record Video",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              width: 150,
              height: 50,
            ),
          if (loading)
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
        ],
      ),
    );
  }
}

class FullscreenCamera extends StatefulWidget {
  @override
  _FullscreenCameraState createState() => _FullscreenCameraState();
}

class _FullscreenCameraState extends State<FullscreenCamera> {
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
          alignment: Alignment.center, child: Text("Camera Error"));
    } else {
      return fullscreenAspectRatio(
        context: context,
        aspectRatio: _cameraController.value.aspectRatio,
        video: (width, height) {
          return Container(
            width: width,
            height: height,
            child: CameraPreview(_cameraController),
          );
        },
        stack: <Widget>[
          Text("Hello :)"),
        ],
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
