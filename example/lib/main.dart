import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gemini_multi_modal_plus/gemini_multi_modal_plus.dart';

void main() => runApp(MaterialApp(home: MainScreen()));

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late AudioChannel _audioChannel;
  late ScreenCaptureChannel _screenChannel;
  late MultiModalLiveClient client;

  ValueNotifier<bool> get isScreenSharing => _screenChannel.isSharing;
  bool _isConnected = false;

  bool isMicOn = false;
  String _chatLog = '';
  bool isProcessingAudio = false;
  @override
  void initState() {
    _initialize();
    super.initState();
  }

  void _initialize() {
    _connectWebSocket();
    _initializeAudio();
    initVideo();
  }

  void initVideo() {
    _screenChannel = ScreenCaptureChannel(
      sendMediaChunk: (base64Data, mimeType) {
        _sendMediaChunk(base64Data, mimeType);
      },
    );
  }

  Future<void> _initializeAudio() async {
    _audioChannel = AudioChannel(
      sendMediaChunk: (base64Data, mimeType) {
        _sendMediaChunk(base64Data, mimeType);
      },
      onAudioSent: () {
        updateLog('USER: Audio input');
      },
    );

    if (kIsWeb || !Platform.isMacOS) {
      await _audioChannel.hasMicPermission();
    }
  }

  void _sendMediaChunk(String base64Data, String mimeType) {
    client.sendRealtimeInput((mimeType: mimeType, data: base64Data));
  }

  void _connectWebSocket() {
    client = MultiModalLiveClient(
      apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
    );

    client.onConnect((_) {
      debugPrint('Connected!');
      setState(() => _isConnected = true);
    });

    client.onLog((e) {
      e = e as StreamingLog;
      if (e.type == 'client.realtimeInput') return;
      debugPrint(e.toString());
    });

    client.onDisconnect((_) {
      debugPrint('Disconnected!');
      setState(() => _isConnected = false);
    });
    client.onSetupComplete((_) {
      updateLog('SYSTEM: Setup');
    });

    client.onReceiveContent((content) {
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

      _audioChannel.processModelAudio(audioData);
    });

    client.onError((error) {
      debugPrint('Error: $error');
      updateLog('SYSTEM: $error');
    });

    client.connect();
  }

  void startCapture() async {
    await _screenChannel.startCapture(context);
    setState(() {});
  }

  void stopCapture() async {
    await _screenChannel.stopCapture();

    setState(() {});
  }

  void updateLog(String message) {
    setState(() {
      _chatLog += '\n$message';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder(
                valueListenable: isScreenSharing,
                builder: (context, isSharing, child) {
                  if (isSharing) {
                    return Expanded(
                      child: Center(
                        child: ScreenShareView(
                          controller: _screenChannel.shareController,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
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
                  ValueListenableBuilder(
                    valueListenable: isScreenSharing,
                    builder: (context, isSharing, child) {
                      return IconButton(
                        icon: Icon(
                          isSharing
                              ? Icons.screen_share_outlined
                              : Icons.stop_screen_share,
                        ),
                        onPressed: !isSharing ? startCapture : stopCapture,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(!isMicOn ? Icons.mic_off : Icons.mic),
                    onPressed: () async {
                      await _audioChannel.toggleMic();
                      setState(() {
                        isMicOn = _audioChannel.isMicOn;
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    client.disconnect();
    _audioChannel.dispose();
    _screenChannel.stopCapture();
    super.dispose();
  }
}
