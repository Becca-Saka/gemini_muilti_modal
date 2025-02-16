import 'base_live_client.dart';
import 'models/config_model.dart';
import 'type_definitions.dart';

class MultiModalLiveClient {
  late String url;

  MultiModalLiveClient({required String apiKey, String? url}) {
    client = BaseMultiModalLiveClient(apiKey: apiKey, url: url);
  }
  late BaseMultiModalLiveClient client;

  void onConnect(void Function(dynamic) callback) =>
      client.on('open', callback);
  void onLog(void Function(dynamic) callback) => client.on('log', callback);
  void onDisconnect(void Function(dynamic) callback) =>
      client.on('close', callback);
  void onSetupComplete(void Function(dynamic) callback) =>
      client.on('setup', callback);
  void onReceiveContent(void Function(dynamic) callback) =>
      client.on('content', callback);
  // onModelTurnStart(void Function(dynamic) callback) {
  //   client.on('content', callback);
  //   //TODO:
  // }
  void onModelTurnComplete(void Function(dynamic) callback) =>
      client.on('turncomplete', callback);
  void onAudioReceived(void Function(GenerativeContentBlob) callback) {
    client.on('audio', (data) {
      if (data is GenerativeContentBlob) {
        callback(data);
      }
    });
  }

  void onError(void Function(dynamic) callback) => client.on('error', callback);

  void connect([ModelConfig? model]) => client.connect(model ?? ModelConfig());

  void sendRealtimeInput(GenerativeContentBlob blob) =>
      client.sendRealtimeInput([blob]);

  void sendRealtimeInputList(List<GenerativeContentBlob> chunks) =>
      client.sendRealtimeInput(chunks);

  void disconnect() => client.disconnect();
}
