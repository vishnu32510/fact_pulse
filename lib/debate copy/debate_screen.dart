import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fact_pulse/authentication/authentication_bloc/authentication_bloc.dart';
import 'package:fact_pulse/authentication/authentication_enums.dart';
import 'package:fact_pulse/core/utils/widgets/custom_bottom_sheet.dart';
import 'package:fact_pulse/models/perplexity_response_model.dart';
import 'package:fact_pulse/debate/prompts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perplexity_flutter/perplexity_flutter.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DebateScreen extends StatefulWidget {
  final String debateId;
  final String topic;
  const DebateScreen({super.key, required this.debateId, required this.topic});

  @override
  State<DebateScreen> createState() => _DebateScreenState();
}

class _DebateScreenState extends State<DebateScreen> {
  late stt.SpeechToText _speech;
  late PerplexityClient _client;
  late final String uid;
  String _fullTranscript = '';
  String textChunks = "";

  final _transcriptionController = StreamController<String>.broadcast();
  final _debateModelController = StreamController<PerplexityResponseModel>.broadcast();
  final _isListeningController = StreamController<bool>.broadcast();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status == AuthenticationStatus.authenticated) {
      uid = authState.user.id;
    }
    _speech = stt.SpeechToText();
    _client = PerplexityClient(apiKey: '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');
    _initializeSpeech();
    // Once user & widget.debateId are ready, do:
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupDebateDoc());
  }

  Future<void> _setupDebateDoc() async {
    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status != AuthenticationStatus.authenticated) return;
    final uid = authState.user.id;
    final debateDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('debates')
        .doc(widget.debateId);

    final snapshot = await debateDoc.get();
    if (!snapshot.exists) {
      // First time: seed all fields including an empty response
      await debateDoc.set({
        'topic': widget.topic,
        'createdAt': FieldValue.serverTimestamp(),
        'response': '',
        'complete': false,
      });
    } else {
      // Already exists: only ensure topic is up to date
      await debateDoc.set({'lastOpenedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      // … and load the existing response into your transcription stream
      final data = snapshot.data();
      if (data != null && data['response'] is String) {
        _fullTranscript = data['response'] as String;
        if (_fullTranscript.isNotEmpty) {
          _transcriptionController.add(_fullTranscript);
        }
      }
    }
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize();
  }

  Future<void> _startListening() async {
    if (await _speech.initialize()) {
      _fullTranscript = _fullTranscript + textChunks;
      _isListeningController.add(true);
      _speech.listen(onResult: _onSpeechResult, listenMode: stt.ListenMode.dictation);
    }
  }

  Future<void> _onSpeechResult(stt.SpeechRecognitionResult result) async {
    final prevLen = '$_fullTranscript $textChunks'.split(' ').length;
    textChunks = result.recognizedWords;
    _transcriptionController.add('$_fullTranscript $textChunks');
    final results = '$_fullTranscript $textChunks';
    final currLen = results.split(" ").length;
    if (prevLen - currLen >= 7) {
      _queryFactCheck(results);
    }
  }

  void _stopListening() {
    _isListeningController.add(false);
    _speech.stop();
  }

  Future<void> _queryFactCheck(String prompt) async {
    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status != AuthenticationStatus.authenticated) return;
    final uid = authState.user.id;

    final debateDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('debates')
        .doc(widget.debateId);

    final systemPrompt = loadDebateSystemPrompt(topic: widget.topic);
    final request = ChatRequestModel.defaultRequest(
      systemPrompt: systemPrompt,
      prompt: prompt,
      stream: false,
      model: PerplexityModel.sonar,
    );

    try {
      final response = await _client.sendMessage(requestModel: request);
      final decoded = jsonDecode(response.content);
      final model = PerplexityResponseModel.fromJson(decoded);

      await debateDoc.set({
        'response': prompt,
        'complete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Batch-write each claim into its own doc
      final batch = _firestore.batch();
      final claimsCol = debateDoc.collection('claims');
      for (final c in model.claims ?? []) {
        final doc = claimsCol.doc();
        batch.set(doc, {
          'claim': c.claim,
          'rating': c.rating,
          'explanation': c.explanation,
          'sources': c.sources,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      // Optional: record error on parent doc
      await debateDoc.set({'error': e.toString()}, SetOptions(merge: true));
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(uid)
                      .collection('debates')
                      .doc(widget.debateId)
                      .collection('claims')
                      .orderBy('createdAt')
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snap.data!.docs;
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final claim = Claims(
                          claim: data['claim'] as String?,
                          rating: data['rating'] as String?,
                          explanation: data['explanation'] as String?,
                          sources: (data['sources'] as List<dynamic>?)?.cast<String>(),
                        );
                        return _buildClaimBubble(
                          claim,
                          onTap: () => CustomBottomSheet().showLinksSheet(ctx, claim.sources ?? []),
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

  // Add this helper if you like:
  Widget _buildClaimBubble(Claims claim, {required VoidCallback onTap}) {
    final isFor = claim.type == 'FOR';
    final bgColor = isFor ? Colors.green.shade50 : Colors.red.shade50;
    final radius = BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: isFor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            claim.rating ?? '',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: isFor ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Visibility(visible: !isFor, child: Icon(Icons.link)),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: bgColor, borderRadius: radius),
                  child: Column(
                    crossAxisAlignment: isFor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Text(claim.explanation ?? '', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              Visibility(visible: isFor, child: Icon(Icons.link)),
            ],
          ),
        ),

        // Claim below bubble
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            claim.claim ?? '',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
