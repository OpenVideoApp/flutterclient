import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutterclient/logging.dart';

final ffmpeg = new FlutterFFmpeg();

enum VideoClipState { Recording, Processing, Processed }

class VideoClip {
  String dir;
  String filename;
  String extension;
  bool usesBackCam;
  VideoClipState state;

  VideoClip({
    @required this.dir,
    @required this.filename,
    this.extension = "mp4",
    this.usesBackCam = false,
    this.state = VideoClipState.Recording,
  });

  get path {
    return dir + filename + "." + extension;
  }
}

class VideoClips {
  String _dir, _listFile, _outputFile;
  int _nextClipId = 0;

  Future<void> _future = Future(() {});
  List<VideoClip> _clips = [];

  VideoClips({@required dir, listFile = "videos.txt", outputFile = "videos.mp4"}) {
    _dir = dir;
    _listFile = listFile;
    _outputFile = outputFile;

    reset();
  }

  get length {
    return _nextClipId;
  }

  Future<void> reset() async {
    _clips.clear();
    _nextClipId = 0;
    var recDir = Directory(_dir);
    if (recDir.existsSync()) {
      await recDir.delete(recursive: true);
    }
    return recDir.create(recursive: true);
  }

  Future<void> processLatestClip() async {
    if (_nextClipId < 0) {
      logger.w("Tried to process clip #$_nextClipId but only ${_clips.length} clips are saved!");
      return;
    }
    var clip = _clips[_nextClipId];
    if (clip.state != VideoClipState.Recording) {
      logger.w("Tried to process clip #$_nextClipId with incorrect state ${clip.state}!");
    }
    _nextClipId++;
    clip.state = VideoClipState.Processing;

    var path = _dir + clip.filename + "." + clip.extension;
    var processedPath = _dir + clip.filename + "-processed." + clip.extension;

    var filter = "fps=fps=30" + (!clip.usesBackCam ? ",hflip" : "");
    var meta = "rotate='90'";

    _future = _future.then((_) {
      logger.i("Processing clip ${clip.filename}..");
      return ffmpeg.execute("-i $path -b:v 2M -vf '$filter' -metadata:s:v $meta $processedPath").then((rc) {
        clip.state = VideoClipState.Processed;
        if (rc != 0) {
          logger.w("Failed to process clip '${clip.filename}'! Received return code $rc");
        } else {
          clip.filename += "-processed";
        }
      });
    });
  }

  String create({@required bool usingBackCam}) {
    var clip = VideoClip(
      dir: _dir,
      filename: "/clip-$_nextClipId",
    );
    _clips.add(clip);
    return clip.path;
  }

  Future<String> writeList() async {
    var filePath = _dir + "/" + _listFile;
    _future = _future.then((_) async {
      var file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      String files = "";
      for (var clip in this._clips) {
        var path = _dir + clip.filename + "." + clip.extension;
        logger.i("Adding clip ${clip.filename} to list with path '$path'!");
        files += "file '$path'\n";
      }
      await file.writeAsString(files);
      return file.path;
    });
    return _future.then((_) {
      return filePath;
    });
  }

  Future<bool> combine() async {
    var list = await writeList();
    var rc = await ffmpeg.execute("-f concat -safe 0 -i $list -c copy ${getOutputPath()}");
    logger.i("FFmpeg finished with return code $rc");
    return rc == 0;
  }

  String getOutputPath() {
    return _dir + "/" + _outputFile;
  }
}
