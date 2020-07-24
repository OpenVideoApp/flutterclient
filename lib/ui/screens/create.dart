import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutterclient/api/auth.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/ui/widget/video_screen.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart';

List<CameraDescription> cameras;

Future<void> initCameras() async {
  cameras = await availableCameras();
}

class CreateTab extends StatefulWidget {
  @override
  _CreateTabState createState() => _CreateTabState();
}

class _CreateTabState extends State<CreateTab> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          BorderedFlatButton(
            onTap: () async {
              var file = await ImagePicker().getVideo(
                source: ImageSource.camera,
                preferredCameraDevice: CameraDevice.front,
                maxDuration: Duration(seconds: 60),
              );

              if (file == null) return;

              var query = await graphqlClient.value.mutate(MutationOptions(
                documentNode: gql("""
                  mutation RequestVideoUpload {
                    request: requestVideoUpload {
                      ... on UploadableVideo {id uploadURL}
                      ... on APIError {error}
                    }
                  }
                """),
              ));

              if (query.hasException) {
                return logger.w("Failed to get upload URL: ${query.exception}");
              }

              var request = query.data["request"];
              if (request["error"] != null) {
                return logger.w(
                  "Failed to get upload URL: ${request["error"]}",
                );
              }

              var res = await put(
                request["uploadURL"],
                body: await file.readAsBytes(),
                headers: {"Content-Type": "video/mp4"},
              );

              if (res.statusCode != 200) {
                return logger.w(
                  "Failed to upload video (${res.statusCode}): ${res.body}",
                );
              }

              query = await graphqlClient.value.mutate(MutationOptions(
                documentNode: gql("""
                  mutation VideoUploadFinished(\$id: String!) {
                    result: handleCompletedVideoUpload(videoId: \$id) {
                      ... on APIResult {success}
                      ... on APIError {error}
                    }
                  }
                """),
                variables: {
                  "id": request["id"],
                },
              ));

              if (query.hasException) {
                return logger.w(
                    "Failed to get complete video upload: ${query.exception}");
              }

              var result = query.data["result"];
              if (result["error"] != null) return logger.w("Failed to handle completed upload: ${result["error"]}");

              logger.i("Video upload handled: ${result["success"]}");
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
