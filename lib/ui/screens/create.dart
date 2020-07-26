import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterclient/api/upload.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/ui/widget/video_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

List<CameraDescription> cameras;

Future<void> initCameras() async {
  cameras = await availableCameras();
}

class RecordingController {
  void Function(RecordingController) callback;
  Duration recorded = Duration.zero;
  bool startedRecording = false;
  bool recording = false;

  RecordingController({@required this.callback});

  void toggle() {
    logger.i("toggle $startedRecording");
    recording = !recording;
    callback(this);
    startedRecording = true;
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

class CloseButton extends StatelessWidget {
  final IconData icon;

  CloseButton({this.icon = Icons.clear});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.all(5),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Icon(
              this.icon,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  _NextButton({@required this.onPressed, @required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.all(5),
        child: GestureDetector(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Text(
              this.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
              ),
            ),
          ),
        ),
      ),
    );
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
                  var builder = await requestUpload(_videoDescController.text, _soundDescController.text);
                  if (builder == null) return;

                  uploadVideo(builder, widget.filename).then((success) {
                    logger.i("Uploaded video: $success");
                  }).catchError((error) {
                    logger.w("Upload failed: $error}");
                  });
                },
                child: Text("Upload"),
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
  final String filename;

  RecordingEditingScreen({@required this.filename});

  @override
  _RecordingEditingScreenState createState() => _RecordingEditingScreenState();
}

class _RecordingEditingScreenState extends State<RecordingEditingScreen> {
  VideoPlayerController _controller;
  Future<void> _controllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filename));
    _controllerFuture = _controller.initialize();
    _controllerFuture.then((_) {
      _controller.setLooping(true);
      _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: fullscreenAspectRatio(
          context: context,
          aspectRatio: _controller.value.aspectRatio,
          video: (w, h) {
            return FutureBuilder(
              future: _controllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
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
                  return Center(child: CircularProgressIndicator());
                }
              },
            );
          },
          stack: <Widget>[
            CloseButton(icon: Icons.arrow_back),
            _NextButton(
              text: "Next",
              onPressed: () {
                _controller.pause().then((_) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return VideoDetailsScreen(
                          filename: widget.filename,
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
    _controller.dispose();
    super.dispose();
  }
}

class FullscreenCamera extends StatefulWidget {
  @override
  _FullscreenCameraState createState() => _FullscreenCameraState();
}

class _FullscreenCameraState extends State<FullscreenCamera> {
  CameraController _cameraController;
  RecordingController _recordingController;
  String _tempPath;

  @override
  void initState() {
    super.initState();
    _recordingController = RecordingController(callback: (controller) {
      if (controller.recording) {
        if (!controller.startedRecording) {
          logger.i("Started recording");
          _cameraController.startVideoRecording(_tempPath);
        } else {
          logger.i("Recording resumed");
          _cameraController.resumeVideoRecording();
        }
      } else {
        logger.i("Recording paused");
        _cameraController.pauseVideoRecording();
        setState(() {});
      }
    });
    getTemporaryDirectory().then((dir) async {
      _tempPath = dir.path + "/video.mp4";
      var file = File(_tempPath);
      if (await file.exists()) {
        file.delete();
      }
    });
    initCameras().then((_) {
      if (cameras.length == 0) return;
      _cameraController = CameraController(cameras[cameras.length == 1 ? 0 : 1], ResolutionPreset.veryHigh);
      _cameraController.initialize().then((_) {
        if (!mounted) return;
        _cameraController.prepareForVideoRecording();
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(children: <Widget>[
            CloseButton(),
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
          child: fullscreenAspectRatio(
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
              CloseButton(),
              if (_recordingController.startedRecording)
                _NextButton(
                  text: "Done",
                  onPressed: () {
                    if (_recordingController.recording) return;
                    _cameraController.stopVideoRecording().then((_) {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) {
                            return RecordingEditingScreen(
                              filename: _tempPath,
                            );
                          },
                          transitionsBuilder: slideFrom(1, 0),
                        ),
                      ).then((_) {
                        setState(() {
                          File(_tempPath).delete();
                          _recordingController.startedRecording = false;
                        });
                      });
                    });
                  },
                ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: RecordingButton(
                  controller: _recordingController,
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
                  controller: PageController(viewportFraction: 0.15, initialPage: 1),
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
    _cameraController?.dispose();
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
