// main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:gemini_multi_modal/gemini_multi_modal.dart'
    show GenerativeContentBlob;

import 'audio_player_service.dart';
import 'audio_record_service.dart';
import 'log_level.dart';

class AudioChannel {
  final Function(String base64Data, String mimeType) sendMediaChunk;
  final Function() onAudioSent;
  AudioChannel({required this.sendMediaChunk, required this.onAudioSent});

  bool isMicOn = false;
  Timer? _timer;
  List<Uint8List> audioData = [];

  Future<bool> hasMicPermission() => _audioService.hasPermission();
  final AudioRecordService _audioService = AudioRecordService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  Future<void> initialize({
    int? threshold,
    Function(int)? onFeed,
    LogLevel? logLevel,
  }) async {
    await _audioPlayerService.initializeAudio(
      threshold: threshold,
      onFeed: onFeed,
      logLevel: logLevel?.fpcmLogLevel(),
    );
  }

  Future<void> toggleMic() async {
    if (isMicOn) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  void testAudio(Uint8List data) {
    _audioPlayerService.play(translateAudio(audioData));
    audioData.add(data);
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer(const Duration(milliseconds: 25), () {
      _audioPlayerService.play(translateAudio(audioData));
      audioData.clear();
      onAudioSent();
    });
  }

  Uint8List translateAudio(List<Uint8List> data) {
    Uint8List result = Uint8List(0);
    for (var element in data) {
      result = Uint8List.fromList([...result, ...element]);
    }
    return result;
  }

  Future<void> _startRecording() async {
    try {
      _audioService.startRecording(sendAudio);
      isMicOn = true;
    } catch (e) {
      print('Error starting recording: $e');
      isMicOn = false;
    }
  }

  void sendAudio(Uint8List data) {
    audioData.add(data);
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer(const Duration(milliseconds: 25), () {
      final data = translateAudio(audioData);
      final encodedAudio = base64Encode(data);

      sendMediaChunk(encodedAudio, 'audio/pcm;rate=16000');

      audioData.clear();
      onAudioSent();
    });
  }

  Future<void> _stopRecording() async {
    await _audioService.stopRecording();
    isMicOn = false;
    _timer?.cancel();
    _timer = null;
    audioData.clear();
  }

  void processModelAudio(dynamic audioData) {
    if (audioData is GenerativeContentBlob) {
      final sampleRate = audioData.mimeType.split(';')[1].split('=')[1];
      _playAudio(audioData.data, int.tryParse(sampleRate));
    }
  }

  Future<void> _playAudio(String base64Audio, int? sampleRate) async {
    final audioData = base64Decode(base64Audio);
    _audioPlayerService.play(audioData, sampleRate: sampleRate);
  }

  void stopAudio() {
    _audioPlayerService.stop();
  }

  void dispose() {
    _audioPlayerService.dispose();
    _audioService.dispose();
  }
}
