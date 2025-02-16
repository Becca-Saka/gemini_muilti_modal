import 'dart:typed_data';

import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

class AudioPlayerService {
  int sampleRate = 16000;

  int remainingFrames = 0;
  bool initialized = false;
  Future<void> initializeAudio({
    int? threshold,
    Function(int)? onFeed,
    LogLevel? logLevel,
  }) async {
    if (logLevel != null) {
      await FlutterPcmSound.setLogLevel(logLevel);
    }
    if (threshold != null) {
      await FlutterPcmSound.setFeedThreshold(threshold);
    }
    if (onFeed != null) {
      FlutterPcmSound.setFeedCallback(onFeed);
    }
    await setup();
    await FlutterPcmSound.resumeAudioContext();
  }

  Future<void> setup() async {
    await FlutterPcmSound.setup(
      sampleRate: sampleRate,
      channelCount: 1,
    );
  }

  void dispose() => FlutterPcmSound.release();

  Future<void> play(Uint8List data, {int? sampleRate = 16000}) async {
    if (sampleRate != null && sampleRate != this.sampleRate) {
      this.sampleRate = sampleRate;
      await setup();
    }

    ByteData pcmBytes = data.buffer.asByteData();
    FlutterPcmSound.feed(PcmArrayInt16(bytes: pcmBytes));
  }

  void stop() {
    remainingFrames = 0;

    FlutterPcmSound.clearBuffer();
  }
}
