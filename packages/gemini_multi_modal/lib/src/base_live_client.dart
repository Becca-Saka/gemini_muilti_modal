import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:gemini_multi_modal/src/models/config_model.dart';
import 'package:universal_html/html.dart' as html;
import 'package:web_socket_client/web_socket_client.dart';

import 'event_emitter.dart';
import 'event_parser.dart';
import 'type_definitions.dart';

class BaseMultiModalLiveClient extends EventEmitter {
  WebSocket? _ws;
  late String url;
  final List<Map<String, dynamic>> _previousTurns = [];
  BaseMultiModalLiveClient({String? url, required String apiKey}) {
    this.url = url ??
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent';
    this.url += '?key=$apiKey';
  }

  void log(String type, dynamic message) {
    final log = (date: DateTime.now(), type: type, message: message);
    emit('log', log);
  }

  Future<bool> connect(ModelConfig config) async {
    final ws = WebSocket(Uri.parse(url));
    _ws = ws;

    ws.messages.listen((message) async {
      try {
        if (message is List<int> || message is html.Blob) {
          final decodedMessage = await parseMessage(message);
          await receive(decodedMessage);
        }
      } catch (e) {
        log('server.error', 'error processing message: $message');
      }
    });

    ws.connection.listen((state) {
      if (state is Connected) {
        log('client.open', 'connected to socket');
        emit('open');

        final setupMessage = {
          'setup': config.toJson(),
        };
        _sendDirect(setupMessage);
        log('client.send', 'setup');
      }
      if (state is Disconnected) {
        log('server.close', 'disconnected ${state.reason}');
        emit('close', null);
      }
    });

    return true;
  }

  bool disconnect() {
    if (_ws != null) {
      _ws!.close();
      _ws = null;
      log('client.close', 'Disconnected');
      return true;
    }
    return false;
  }

  void _sendDirect(Map<String, dynamic> request) {
    if (_ws == null) {
      throw Exception('WebSocket is not connected');
    }
    final str = jsonEncode(request);
    _ws!.send(str);
  }

  Future<void> receive(Uint8List data) async {
    final response = jsonDecode(utf8.decode(data));

    if (response.containsKey('toolCall')) {
      log('server.toolCall', response);
      emit('toolcall', response['toolCall']);
      return;
    }

    if (response.containsKey('toolCallCancellation')) {
      log('receive.toolCallCancellation', response);
      emit('toolcallcancellation', response['toolCallCancellation']);
      return;
    }

    if (response.containsKey('setupComplete')) {
      log('server.send', 'setupComplete');
      emit('setupcomplete');
      return;
    }

    if (response.containsKey('serverContent')) {
      final serverContent = response['serverContent'];

      if (serverContent.containsKey('interrupted')) {
        log('receive.serverContent', 'interrupted');
        emit('interrupted');
        return;
      }

      if (serverContent.containsKey('end_of_turn')) {
        log('server.send', 'turnComplete');
        emit('turncomplete');
      }

      if (serverContent.containsKey('modelTurn')) {
        var parts = serverContent['modelTurn']['parts'] as List;

        final audioParts = parts
            .where(
              (p) =>
                  p['inlineData'] != null &&
                  p['inlineData']['mimeType'].startsWith('audio/pcm'),
            )
            .toList();

        final base64s = audioParts
            .map((p) => p['inlineData'] as Map?)
            .where((data) => data != null)
            .toList();

        final otherParts = parts.where((p) => !audioParts.contains(p)).toList();

        for (final b64 in base64s) {
          if (b64 != null) {
            final mimeType = b64['mimeType'];
            final streamData = b64['data'] as String;
            final data = base64Decode(streamData);
            emit(
              'audio',
              (data: streamData, mimeType: mimeType) as GenerativeContentBlob,
            );
            log('server.audio', 'buffer (${data.length})');
          }
        }

        if (otherParts.isEmpty) return;

        final content = {
          'modelTurn': {'parts': otherParts},
        };
        emit('content', content);
        log('server.content', response);
      }
    } else {
      log('server.error', 'received unmatched message: $response');
    }
  }

  void sendRealtimeInput(List<GenerativeContentBlob> chunks) {
    var hasAudio = false;
    var hasVideo = false;

    for (final chunk in chunks) {
      if (chunk.mimeType.contains('audio')) hasAudio = true;
      if (chunk.mimeType.contains('image') ||
          chunk.mimeType.contains('application')) {
        hasVideo = true;
      }
      if (hasAudio && hasVideo) break;
    }

    final message = hasAudio && hasVideo
        ? 'audio + video'
        : hasAudio
            ? 'audio'
            : hasVideo
                ? 'video'
                : 'unknown';

    final data = {
      'realtime_input': {
        'media_chunks': chunks
            .map((c) => {'mime_type': c.mimeType, 'data': c.data})
            .toList(),
      },
    };

    _sendDirect(data);
    log('client.realtimeInput', message);
  }

  void sendToolResponse(Map<String, dynamic> toolResponse) {
    final message = {'toolResponse': toolResponse};
    _sendDirect(message);
    log('client.toolResponse', message);
  }

  void send(dynamic parts, [bool turnComplete = true]) {
    parts = parts is List ? parts : [parts];

    final content = {'role': 'user', 'parts': parts};
    log('client.send', parts.toString());

    final clientContentRequest = {
      'clientContent': {
        'turns': [content],
        'turnComplete': turnComplete,
      },
    };

    _sendDirect(clientContentRequest);
    log('client.send', clientContentRequest);
    _storeTurn(content);
  }

  void sendWithTurnHistory(dynamic parts, [bool turnComplete = true]) {
    parts = parts is List ? parts : [parts];
    final previousTurns = _getPreviousTurns();
    final content = {'role': 'user', 'parts': parts};
    log('client.send', parts.toString());
    final allTurns = [...previousTurns, content];
    final clientContentRequest = {
      'clientContent': {'turns': allTurns, 'turnComplete': turnComplete},
    };

    _sendDirect(clientContentRequest);
    log('client.send', clientContentRequest);
    _storeTurn(content);
  }

  List<Map<String, dynamic>> _getPreviousTurns() {
    return List.from(_previousTurns);
  }

  void _storeTurn(Map<String, dynamic> turn) {
    _previousTurns.add(turn);
  }
}
