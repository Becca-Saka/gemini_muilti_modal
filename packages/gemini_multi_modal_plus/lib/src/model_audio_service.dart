// main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:gemini_multi_modal/gemini_multi_modal.dart'
    show GenerativeContentBlob;

import 'audio_player_service.dart';
import 'audio_service.dart';

class ModelAudioService {
  final Function(String base64Data, String mimeType) sendMediaChunk;
  final Function() onAudioSent;
  ModelAudioService({required this.sendMediaChunk, required this.onAudioSent});
  bool isMicOn = false;
  Future<bool> hasMicPermission() => _audioService.hasPermission();
  final AudioService _audioService = AudioService();
  final AuioPlayerService _audioPlayerService = AuioPlayerService();

  List<Uint8List> audioData = [];
  Timer? _timer;

  Future<void> initialize() async {
    await _audioPlayerService.initializeAudio();
  }

  Future<void> toggleMic() async {
    if (isMicOn) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  void testAudio(Uint8List data) {
    audioData.add(data);
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer(const Duration(milliseconds: 500), () {
      _audioPlayerService.stream(translateAudio(audioData));
      audioData = [];
      onAudioSent();
    });
  }

  void sendAudio(Uint8List data) {
    audioData.add(data);
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer(const Duration(milliseconds: 900), () {
      final data = translateAudio(audioData);
      final encodedAudio = base64Encode(data);
      sendMediaChunk(encodedAudio, 'audio/pcm;rate=16000');

      audioData = [];
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

  Future<void> _stopRecording() async {
    await _audioService.stopRecording();
    isMicOn = false;
    // //TODO: remvoe after test
    // _audioPlayerService.stopFeeding();
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
    _audioPlayerService.stream(audioData, sampleRate: sampleRate);
  }

  void stopAudio() {
    _audioPlayerService.stopFeeding();
  }

  void dispose() {
    _audioPlayerService.dispose();
    _audioService.dispose();
  }
}
