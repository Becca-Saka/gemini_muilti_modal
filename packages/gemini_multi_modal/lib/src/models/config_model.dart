// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

class ModelConfig {
  final String model;
  final GenerationConfig generationConfig;
  final String? systemInstruction;
  final List<Map<String, dynamic>>? tools;

  const ModelConfig({
    this.model = 'models/gemini-2.0-flash-exp',
    this.generationConfig = const GenerationConfig(),
    this.systemInstruction,
    this.tools,
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      model: json['model'],
      generationConfig: GenerationConfig.fromJson(json['generationConfig']),
      systemInstruction: json['systemInstruction'],
      tools: json['tools'] == null
          ? null
          : List<Map<String, dynamic>>.from(json['tools']),
    );
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'generationConfig': generationConfig.toJson(),
        if (systemInstruction != null) 'systemInstruction': systemInstruction,
        if (tools != null) 'tools': tools,
      };

  @override
  String toString() => jsonEncode(toJson());
}

class GenerationConfig {
  final int? candidateCount;
  final int? maxOutputTokens;
  final double? temperature;
  final double? topP;
  final int? topK;
  final double? presencePenalty;
  final double? frequencyPenalty;
  final List<String>? responseModalities;
  final VoiceConfig? speechConfig;

  const GenerationConfig({
    this.candidateCount,
    this.maxOutputTokens,
    this.temperature,
    this.topP,
    this.topK,
    this.presencePenalty,
    this.frequencyPenalty,
    this.responseModalities,
    this.speechConfig,
  });

  factory GenerationConfig.fromJson(Map<String, dynamic> json) {
    return GenerationConfig(
      candidateCount: json['candidateCount'],
      maxOutputTokens: json['maxOutputTokens'],
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['topP'] as num?)?.toDouble(),
      topK: json['topK'],
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble(),
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble(),
      responseModalities: (json['responseModalities'] as List?)?.cast<String>(),
      speechConfig: json['speechConfig'] != null
          ? VoiceConfig.fromJson(json['speechConfig'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (candidateCount != null) data['candidateCount'] = candidateCount;
    if (maxOutputTokens != null) data['maxOutputTokens'] = maxOutputTokens;
    if (temperature != null) data['temperature'] = temperature;
    if (topP != null) data['topP'] = topP;
    if (topK != null) data['topK'] = topK;
    if (presencePenalty != null) data['presencePenalty'] = presencePenalty;
    if (frequencyPenalty != null) data['frequencyPenalty'] = frequencyPenalty;
    if (responseModalities != null)
      data['responseModalities'] = responseModalities;
    if (speechConfig != null) data['speechConfig'] = speechConfig!.toJson();
    return data;
  }
}

typedef CustomVoiceConfig = Map<String, dynamic>;

class VoiceConfig {
  final String? voiceName;
  final CustomVoiceConfig? customConfig;

  VoiceConfig({
    this.voiceName = "Puck",
    this.customConfig,
  });

  factory VoiceConfig.fromJson(Map<String, dynamic> json) {
    final customConfig = Map<String, dynamic>.from(json)..remove('voiceName');
    return VoiceConfig(
      voiceName: json['voiceName'],
      customConfig: customConfig.isNotEmpty ? customConfig : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (voiceName != null) data['voiceName'] = voiceName;
    if (customConfig != null) data.addAll(customConfig!);
    return data;
  }
}
