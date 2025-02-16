import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screen_share/flutter_screen_share.dart';

class ScreenCaptureChannel {
  ScreenShareController shareController = ScreenShareController();
  final Function(String base64Data, String mimeType) sendMediaChunk;
  EncodingOptions? encodingOptions;
  ValueNotifier<bool> get isSharing => shareController.isSharing;
  String frameMimeType = 'image/jpeg';
  ScreenCaptureChannel({
    required this.sendMediaChunk,
    this.encodingOptions,
  });

  Future<void> startCapture(
    BuildContext context, {
    Widget Function(List<Display>)? builder,
  }) async {
    await shareController.startCaptureWithDialog(
      context: context,
      options: encodingOptions,
      builder: builder,
      onData: handleVideoFrame,
    );
  }

  Future<void> startCaptureWithSource(source) async {
    await shareController.startCapture(
      source: source,
      options: encodingOptions,
      onData: handleVideoFrame,
    );
  }

  void handleVideoFrame(Uint8List frame) {
    sendMediaChunk(base64Encode(frame), frameMimeType);
  }

  Future<void> stopCapture() async {
    await shareController.stopCapture();
  }

  void dispose() => stopCapture();
}
