import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gemini_multi_modal_plus/gemini_multi_modal_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MainScreen());
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late ModelAudioService _modelAudioService;
  bool _isConnected = false;

  bool isMicOn = false;
  String _chatLog = '';
  late MultiModalLiveClient client;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    _modelAudioService = ModelAudioService(
      sendMediaChunk: (base64Data, mimeType) {
        _sendMediaChunk(base64Data, mimeType);
      },
      onAudioSent: () {
        updateLog('USER: Audio input');
      },
    );
    // request mic permission
    if (kIsWeb || !Platform.isMacOS) {
      await _modelAudioService.hasMicPermission();
    }
  }

  void updateLog(String message) {
    setState(() {
      _chatLog += '\n$message';
    });
  }

  bool isProcessingAudio = false;
  void _connectWebSocket() {
    client = MultiModalLiveClient(
      apiKey: String.fromEnvironment('GEMINI_API_KEY'),
    );
    client.onConnect((_) {
      debugPrint('Connected!');
      setState(() => _isConnected = true);
    });

    client.onLog((e) => debugPrint('$e'));

    client.onDisconnect((_) {
      debugPrint('Disconnected!');
      setState(() => _isConnected = false);
    });
    client.onSetupComplete((_) {
      updateLog('SYSTEM: Setup');
    });

    client.onRecieveContent((content) {
      debugPrint('Received content: $content');
    });
    client.onModelTurnComplete((content) {
      if (isProcessingAudio) {
        updateLog('GEMINI: Audio response ');
      }
      debugPrint('Received content: $content');
      isProcessingAudio = false;
    });

    client.onAudioReceived((audioData) {
      isProcessingAudio = true;

      _modelAudioService.processModelAudio(audioData);
    });

    client.onError((error) {
      debugPrint('Error: $error');
      updateLog('SYSTEM: $error');
    });

    client.connect(
      generationConfig: {
        'response_modalities': ['AUDIO'],
        'speechConfig': {
          'voiceConfig': {
            'prebuiltVoiceConfig': {'voiceName': "Puck"},
          },
        },
      },
    );
  }

  Uint8List translateAudio(List<Uint8List> data) {
    Uint8List result = Uint8List(0);
    for (var element in data) {
      result = Uint8List.fromList([...result, ...element]);
    }
    return result;
  }

  void _sendMediaChunk(String base64Data, String mimeType) {
    client.sendRealtimeInput((mimeType: mimeType, data: base64Data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chat Log',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
              ),
              Container(
                height: 200,
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(child: Text(_chatLog)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(isMicOn ? Icons.mic_off : Icons.mic),
                    onPressed: () async {
                      await _modelAudioService.toggleMic();
                      setState(() {
                        isMicOn = _modelAudioService.isMicOn;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child:
                        _isConnected
                            ? const Text(
                              'Disconnect',
                              style: TextStyle(color: Colors.red),
                            )
                            : const Text(
                              'Connect',
                              style: TextStyle(color: Colors.green),
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    client.disconnect();
    _modelAudioService.dispose();

    super.dispose();
  }
}
