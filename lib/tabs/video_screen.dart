import 'package:flutter/cupertino.dart';

Widget fullscreenAspectRatio({
    BuildContext context,
    double aspectRatio,
    Widget Function(double width, double height) video,
    List<Widget> stack
  }) {
  MediaQueryData query = MediaQuery.of(context);

  double width = query.size.width;
  double height = query.size.height - query.padding.top - query.padding
    .bottom;

  double videoWidth = width;
  double videoHeight = videoWidth / aspectRatio;

  if (videoHeight < height) {
    videoHeight = height - 56;
    videoWidth = videoHeight * aspectRatio;

    if (videoWidth < width) {
      videoWidth = width;
      videoHeight = videoWidth / aspectRatio;
    }
  }

  return Container(
    width: width,
    height: height,
    alignment: Alignment.bottomCenter,
    child: Stack(
      children: <Widget>[
        Center(
          child: ClipRect(
            child: OverflowBox(
              maxWidth: videoWidth,
              maxHeight: videoHeight,
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.center,
                child: video(videoWidth, videoHeight)
              )
            )
          )
        ),
        Stack(
          children: stack
        )
      ]
    )
  );
}