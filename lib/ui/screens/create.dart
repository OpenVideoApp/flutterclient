import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterclient/api/upload.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/ui/widget/buttons.dart';
import 'package:flutterclient/ui/widget/video/components.dart';
import 'package:flutterclient/video-tools/clips.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

List<CameraDescription> cameras;

Future<void> initCameras() async {
  cameras = await availableCameras();
}

class RecordingController {
  void Function(RecordingController) callback;
  int recorded = 0;
  bool recording = false;

  RecordingController({@required this.callback});

  void toggle() {
    recording = !recording;
    callback(this);
  }
}

class RecordingButton extends StatefulWidget {
  final RecordingController controller;

  RecordingButton({@required this.controller});

  @override
  _RecordingButtonState createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  Animation<double> _outerRingTween;
  Animation<double> _innerRingTween;
  Animation<double> _shapeTween;
  Animation<double> _marginTween;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _outerRingTween = Tween<double>(begin: 90.0, end: 110.0).animate(_controller);
    _innerRingTween = Tween<double>(begin: 70.0, end: 40.0).animate(_controller);
    _shapeTween = Tween<double>(begin: 36.0, end: 10.0).animate(_controller);
    _marginTween = Tween<double>(begin: 10.0, end: 0.0).animate(_controller);

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.controller.toggle();
          if (widget.controller.recording) {
            logger.i("Animating start recording");
            _controller.forward(from: 0);
          } else {
            logger.i("Animating stop recording");
            _controller.animateBack(0);
          }
        });
      },
      child: Container(
        alignment: Alignment.center,
        width: _outerRingTween.value,
        height: _outerRingTween.value,
        margin: EdgeInsets.all(_marginTween.value),
        decoration: new BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.red.withOpacity(0.5),
            width: 8,
          ),
        ),
        child: Container(
          alignment: Alignment.center,
          width: _innerRingTween.value,
          height: _innerRingTween.value,
          decoration: new BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(_shapeTween.value),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class VideoDetailsScreen extends StatefulWidget {
  final String filename;

  VideoDetailsScreen({@required this.filename});

  @override
  _VideoDetailsScreenState createState() => _VideoDetailsScreenState();
}

class _VideoDetailsScreenState extends State<VideoDetailsScreen> {
  TextEditingController _videoDescController;
  TextEditingController _soundDescController;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _videoDescController = TextEditingController();
    _soundDescController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.95),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: TextField(
                controller: _videoDescController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Video Description..",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: TextField(
                controller: _soundDescController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Sound Description..",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: GradientButton(
                onPressed: () async {
                  if (_uploading) {
                    return;
                  }

                  setState(() {
                    _uploading = true;
                  });

                  var builder = await requestUpload(_videoDescController.text, _soundDescController.text);
                  if (builder == null) {
                    setState(() {
                      _uploading = false;
                    });
                    return;
                  }

                  uploadVideo(builder, widget.filename).then((success) {
                    logger.i("Uploaded video: $success");
                    _uploading = false;
                    Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
                  }).catchError((error) {
                    logger.w("Upload failed: $error}");
                    setState(() {
                      _uploading = false;
                    });
                    Scaffold.of(context).showSnackBar(SnackBar(content: Text("Video Upload Failed :(")));
                  });
                },
                child: _uploading ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          backgroundColor: Colors.transparent,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(width: 29),
                      Text("Uploading"),
                    ],
                  ) : Text("Upload"),
                colors: [Colors.green, Colors.lightGreen],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text("Video Details"),
      ),
    );
  }

  void dispose() {
    _videoDescController.dispose();
    _soundDescController.dispose();
    super.dispose();
  }
}

class RecordingEditingScreen extends StatefulWidget {
  final VideoClips clips;

  RecordingEditingScreen({@required this.clips});

  @override
  _RecordingEditingScreenState createState() => _RecordingEditingScreenState();
}

class _RecordingEditingScreenState extends State<RecordingEditingScreen> {
  VideoPlayerController _controller;
  Future<void> _controllerFuture;

  @override
  void initState() {
    super.initState();

    _controllerFuture = widget.clips.combine().then((success) {
      if (!success) return false;
      _controller = VideoPlayerController.file(File(widget.clips.getOutputPath()));
      return _controller.initialize().then((_) {
        _controller.setLooping(true);
        setState(() {
          _controller.play();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool controllerReady = _controller != null && _controller.value.initialized;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FullscreenAspectRatio(
          aspectRatio: controllerReady ? _controller.value.aspectRatio : (1080.0 / 1920.0),
          video: (w, h) {
            return FutureBuilder(
              future: _controllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && controllerReady) {
                  return Container(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        logger.i("tap playback (unimplemented)");
                      },
                      child: VideoPlayer(_controller),
                    ),
                  );
                } else {
                  logger.i("Connection state: ${snapshot.connectionState} ... controller ? $_controller");
                  return Center(child: CircularProgressIndicator());
                }
              },
            );
          },
          children: <Widget>[
            FloatingCloseButton(icon: Icons.arrow_back),
            if (controllerReady)
              FloatingNextButton(
                text: "Next",
                onPressed: () {
                  _controller.pause().then((_) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return VideoDetailsScreen(
                            filename: widget.clips.getOutputPath(),
                          );
                        },
                        transitionsBuilder: slideFrom(1, 0),
                      ),
                    ).then((_) {
                      setState(() {
                        _controller.play();
                      });
                    });
                  });
                },
              )
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        height: 55,
        alignment: Alignment.center,
        child: Text(
          "Video Playback",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class CameraRecordingController {
  RecordingController recordingController;
  CameraController cameraController;

  VoidCallback _listener;

  bool _usingBackCam = false;
  VideoClips clips;

  CameraRecordingController(this._listener) {
    getTemporaryDirectory().then((dir) {
      clips = VideoClips(dir: dir.path + "/rec");
    });

    recordingController = RecordingController(callback: _recordingCallback);

    initCameras().then((_) {
      if (cameras.length < 1) return;
      _initCamera();
    });
  }

  Future<void> _initCamera() async {
    cameraController = CameraController(cameras[getSelectedCameraID()], ResolutionPreset.medium);
    return cameraController.initialize().then((_) {
      cameraController.prepareForVideoRecording();
      _listener();
    });
  }

  Future<void> toggleCamera() async {
    if (cameras.length < 2) return;
    _usingBackCam = !_usingBackCam;
    if (recordingController.recording) {
      await cameraController.stopVideoRecording();
      clips.processLatestClip();
    }
    await cameraController.dispose();
    await _initCamera();
    if (!cameraReady()) {
      logger.w("Camera is not ready after toggling");
      return;
    }

    if (recordingController.recording) {
      await startRecording();
    }

    _listener();
  }

  bool cameraReady() {
    return cameraController != null && cameraController.value.isInitialized;
  }

  int getSelectedCameraID() {
    if (cameras.length == 1) return 0;
    return _usingBackCam ? 0 : 1;
  }

  Future<void> startRecording() async {
    logger.i("Started recording");
    var clipFile = clips.create(usingBackCam: _usingBackCam);
    await cameraController.startVideoRecording(clipFile);
  }

  Future<void> _recordingCallback(RecordingController controller) async {
    if (controller.recording) {
      await startRecording();
      _listener();
    } else {
      logger.i("Recording paused");
      cameraController.stopVideoRecording();
      clips.processLatestClip();
      _listener();
    }
  }

  Widget getPreview() {
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onDoubleTap: toggleCamera,
      child: CameraPreview(cameraController),
    );
  }

  void dispose() {
    cameraController?.dispose();
  }
}

class FullscreenCamera extends StatefulWidget {
  @override
  _FullscreenCameraState createState() => _FullscreenCameraState();
}

class _FullscreenCameraState extends State<FullscreenCamera> {
  CameraRecordingController _controller;
  PageController _modeController;

  @override
  void initState() {
    super.initState();
    _modeController = PageController(
      initialPage: 1,
      viewportFraction: 0.15,
    );
    _controller = CameraRecordingController(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    CameraController cameraController = _controller.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(children: <Widget>[
            FloatingCloseButton(),
            Center(
              child: CircularProgressIndicator(),
            ),
          ]),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: FullscreenAspectRatio(
            aspectRatio: cameraController.value.aspectRatio,
            video: (width, height) {
              return Container(
                width: width,
                height: height,
                child: _controller.getPreview(),
              );
            },
            children: <Widget>[
              FloatingCloseButton(),
              if (_controller.clips.length > 0)
                FloatingNextButton(
                  text: "Done",
                  onPressed: () {
                    if (_controller.recordingController.recording) return;
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return RecordingEditingScreen(
                            clips: _controller.clips,
                          );
                        },
                        transitionsBuilder: slideFrom(1, 0),
                      ),
                    ).then((_) {
                      setState(() {
                        _controller.clips.reset();
                      });
                    });
                  },
                ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: RecordingButton(
                  controller: _controller.recordingController,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          color: Colors.black,
          height: 55,
          alignment: Alignment.center,
          child: Column(
            children: <Widget>[
              Expanded(
                child: PageView(
                  controller: _modeController,
                  children: <Widget>[
                    VideoTypeSetting("15s"),
                    VideoTypeSetting("30s"),
                    VideoTypeSetting("60s"),
                  ],
                ),
              ),
              Text(
                "\u2022",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 5),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class VideoTypeSetting extends StatelessWidget {
  final String name;

  VideoTypeSetting(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      child: Text(
        this.name,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
