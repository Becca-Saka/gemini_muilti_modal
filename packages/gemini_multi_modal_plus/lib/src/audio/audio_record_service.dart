import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

class AudioRecordService {
  final AudioRecorder _record = AudioRecorder();
  StreamSubscription<Uint8List>? _streamSubscription;
  Future<bool> isRecording() => _record.isRecording();
  Future<bool> hasPermission() => _record.hasPermission();

  Future<void> startRecording(Function(Uint8List) onData) async {
    final recordStream = await _record.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _streamSubscription = recordStream.listen(onData);
  }

  Future<void> stopRecording() async {
    await _streamSubscription?.cancel();
    await _record.stop();
  }

  Future<void> resume() async {
    _streamSubscription?.resume();
  }

  Future<void> stop() async {
    _streamSubscription?.pause();
    await _record.stop();
  }

  void dispose() {
    _streamSubscription?.cancel();
    _record.dispose();
  }
}
