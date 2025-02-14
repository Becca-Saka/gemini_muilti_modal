// import 'dart:typed_data';

// import 'package:audioplayers/audioplayers.dart';
// // import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

// class AuioPlayerService {
//   int sampleRate = 16000;

//   int remainingFrames = 0;
//   bool initialized = false;
//   final AudioPlayer audioPlayer = AudioPlayer();
//   Future<void> initializeAudio() async {
//     // await FlutterPcmSound.setLogLevel(LogLevel.verbose);
//     // await setup();
//     // // await FlutterPcmSound.setFeedThreshold(sampleRate ~/ 10);
//     // // FlutterPcmSound.setFeedCallback(_onFeed);
//     // await FlutterPcmSound.resumeAudioContext();
//   }

//   Future<void> setup() async {
//     // await FlutterPcmSound.setup(
//     //   sampleRate: sampleRate,
//     //   channelCount: 1,
//     // );
//   }

//   void dispose() {
//     audioPlayer.dispose();
//     // FlutterPcmSound.release();
//   }

//   Future<void> stream(
//     Uint8List data, {
//     int? sampleRate = 16000,
//     String? mimeType,
//   }) async {
//     if (sampleRate != null && sampleRate != this.sampleRate) {
//       this.sampleRate = sampleRate;
//       await setup();
//     }

//     await audioPlayer.play(BytesSource(data, mimeType: mimeType));
//   }

//   void stopFeeding() {
//     remainingFrames = 0;
//     audioPlayer.stop();
//     // FlutterPcmSound.release();
//     // initializeAudio();
//   }
// }
