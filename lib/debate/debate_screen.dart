import 'dart:async';
import 'dart:convert';

import 'package:fact_pulse/debate/debate_response_model.dart';
import 'package:fact_pulse/debate/prompts.dart';
import 'package:flutter/material.dart';
import 'package:perplexity_flutter/perplexity_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DebateScreen extends StatefulWidget {
  const DebateScreen({super.key});

  @override
  State<DebateScreen> createState() => _DebateScreenState();
}

class _DebateScreenState extends State<DebateScreen> {
  late stt.SpeechToText _speech;
  late PerplexityClient _client;

  final _transcriptionController = StreamController<String>.broadcast();
  final _debateModelController = StreamController<DebateResponseModel>.broadcast();
  final _isListeningController = StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _client = PerplexityClient(
      apiKey: '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',
    );
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize();
  }

  Future<void> _startListening() async {
    if (await _speech.initialize()) {
      _isListeningController.add(true);
      _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          _transcriptionController.add(text);
          if (text.split(' ').length % 7 == 0) {
            _queryFactCheck(text);
          }
        },
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  void _stopListening() {
    _isListeningController.add(false);
    _speech.stop();
  }

  Future<void> _queryFactCheck(String prompt) async {
    final systemPrompt = loadSystemPrompt();
    final request = ChatRequestModel.defaultRequest(
      systemPrompt: systemPrompt,
      prompt: prompt,
      stream: false, // non‐streaming
      model: PerplexityModel.sonar,
    );

    try {
      final response = await _client.sendMessage(requestModel: request);
      final decoded = jsonDecode(response.content);
      final model = DebateResponseModel.fromJson(decoded);
      _debateModelController.add(model);
    } catch (e) {
      _debateModelController.addError('❌ Error: $e');
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _transcriptionController.close();
    _debateModelController.close();
    _isListeningController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Debate Dynamic')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Live transcription
              StreamBuilder<String>(
                stream: _transcriptionController.stream,
                builder: (ctx, snap) => Text(
                  '🎙️ ${snap.data ?? 'Speak something...'}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const Divider(),

              // Parsed debate-claims list
              Expanded(
                child: StreamBuilder<DebateResponseModel>(
                  stream: _debateModelController.stream,
                  builder: (ctx, snap) {
                    if (snap.hasError) {
                      return Center(child: Text(snap.error.toString()));
                    }
                    if (!snap.hasData) {
                      return const Center(child: Text('⏳ Waiting for analysis...'));
                    }
                    final claims = snap.data!.claims ?? [];
                    return ListView.separated(
                      itemCount: claims.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, i) {
                        final c = claims[i];
                        return ListTile(
                          title: Text(c.claim ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rating: ${c.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Explanation: ${c.explanation}'),
                              if (c.sources != null && c.sources!.isNotEmpty)
                                Text('Sources: ${c.sources!.join(', ')}',
                                    style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: StreamBuilder<bool>(
          stream: _isListeningController.stream,
          initialData: false,
          builder: (ctx, snap) => FloatingActionButton(
            onPressed: snap.data! ? _stopListening : _startListening,
            child: Icon(snap.data! ? Icons.stop : Icons.mic),
          ),
        ),
      ),
    );
  }
}
