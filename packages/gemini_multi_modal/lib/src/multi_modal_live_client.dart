import 'base_live_client.dart';
import 'type_definitions.dart';

class MultiModalLiveClient {
  late String url;
  String model = 'models/gemini-2.0-flash-exp';

  MultiModalLiveClient({required String apiKey, String? url}) {
    client = BaseMultimodalLiveClient(apiKey: apiKey, url: url);
  }
  late BaseMultimodalLiveClient client;

  onConnect(void Function(dynamic) callback) => client.on('open', callback);
  onLog(void Function(dynamic) callback) => client.on('log', callback);
  onDisconnect(void Function(dynamic) callback) => client.on('close', callback);
  onSetupComplete(void Function(dynamic) callback) =>
      client.on('setup', callback);
  onRecieveContent(void Function(dynamic) callback) =>
      client.on('content', callback);
  // onModelTurnStart(void Function(dynamic) callback) {
  //   client.on('content', callback);
  //   //TODO:
  // }
  onModelTurnComplete(void Function(dynamic) callback) =>
      client.on('turncomplete', callback);
  onAudioReceived(void Function(GenerativeContentBlob) callback) {
    client.on('audio', (data) {
      if (data is GenerativeContentBlob) {
        callback(data);
      }
    });
  }

  onError(void Function(dynamic) callback) => client.on('error', callback);
  bool isProcessingAudio = false;
  void connect({String? model, Map<String, dynamic>? generationConfig}) {
    client.connect({
      if (model != null) 'model': model,
      if (generationConfig != null) 'generation_config': generationConfig,
    });
  }

  void sendRealtimeInput(GenerativeContentBlob blob) {
    client.sendRealtimeInput([blob]);
  }

  void sendRealtimeInputList(List<GenerativeContentBlob> chunks) {
    client.sendRealtimeInput(chunks);
  }

  void disconnect() {
    client.disconnect();
  }
}
