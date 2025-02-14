import 'dart:typed_data';

import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

class AuioPlayerService {
  int sampleRate = 16000;

  int remainingFrames = 0;
  bool initialized = false;
  Future<void> initializeAudio() async {
    await FlutterPcmSound.setLogLevel(LogLevel.verbose);
    await setup();
    // await FlutterPcmSound.setFeedThreshold(sampleRate ~/ 10);
    // FlutterPcmSound.setFeedCallback(_onFeed);
    await FlutterPcmSound.resumeAudioContext();
  }

  Future<void> setup() async {
    await FlutterPcmSound.setup(
      sampleRate: sampleRate,
      channelCount: 1,
    );
  }

  void dispose() {
    FlutterPcmSound.release();
  }

  Future<void> stream(Uint8List data, {int? sampleRate = 16000}) async {
    if (sampleRate != null && sampleRate != this.sampleRate) {
      this.sampleRate = sampleRate;
      await setup();
    }

    ByteData pcmBytes = data.buffer.asByteData();
    FlutterPcmSound.feed(PcmArrayInt16(bytes: pcmBytes));
    // _onFeed(0);
  }

  void stopFeeding() {
    remainingFrames = 0;
    // FlutterPcmSound.release();
    FlutterPcmSound.clearBuffer();
    // FlutterPcmSound.feed(PcmArrayInt16(bytes: 0))
// initializeAudio();
  }
}
