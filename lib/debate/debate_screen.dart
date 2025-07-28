import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fact_pulse/authentication/authentication_bloc/authentication_bloc.dart';
import 'package:fact_pulse/authentication/authentication_enums.dart';
import 'package:fact_pulse/core/utils/app_extensions.dart';
import 'package:fact_pulse/core/utils/widgets/custom_bottom_sheet.dart';
import 'package:fact_pulse/core/widgets/fact_check_app_bar.dart';
import 'package:fact_pulse/core/widgets/recording_fab.dart';
import 'package:fact_pulse/models/perplexity_response_model.dart';
import 'package:fact_pulse/debate/prompts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:perplexity_flutter/perplexity_flutter.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/utils/app_enums.dart';

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
  
  // Controllers for streams
  final _isListeningController = StreamController<bool>.broadcast();
  
  // Scroll controllers to maintain scroll position across layout changes
  final ScrollController _transcriptionScrollController = ScrollController();
  final ScrollController _claimsScrollController = ScrollController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status == AuthenticationStatus.authenticated) {
      uid = authState.user.id;
    }
    _speech = stt.SpeechToText();
          // Use environment variable for API key
      _client = PerplexityClient(apiKey: dotenv.env["PERPLEXITY_API_KEY"] ?? "");
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
      // Load the existing response
      final data = snapshot.data();
      if (data != null && data['response'] is String) {
        _fullTranscript = data['response'] as String;
      }
    }
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize();
  }

  Future<void> _startListening() async {
    if (await _speech.hasPermission) {
      _fullTranscript = _fullTranscript + textChunks;
      _isListeningController.add(true);
      _speech.listen(onResult: _onSpeechResult, listenFor: Duration(hours: 2), pauseFor: Duration(hours: 2), listenOptions: stt.SpeechListenOptions(listenMode: stt.ListenMode.dictation));
    }
  }

  Future<void> _onSpeechResult(stt.SpeechRecognitionResult result) async {
    textChunks = result.recognizedWords;
    
    // Update Firebase with the current transcription
    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status == AuthenticationStatus.authenticated) {
      final uid = authState.user.id;
      final debateDoc = _firestore
          .collection('users')
          .doc(uid)
          .collection('debates')
          .doc(widget.debateId);
      
      await debateDoc.update({
        'response': '$_fullTranscript $textChunks',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    // Scroll to the bottom of the transcription
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transcriptionScrollController.hasClients) {
        _transcriptionScrollController.animateTo(
          _transcriptionScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    if (textChunks.split(' ').length % 7 == 0) {
      _queryFactCheck('$_fullTranscript $textChunks');
    }
  }

  void _stopListening() {
    _isListeningController.add(false);
    _speech.stop();
    
    // Update Firebase with the final transcription
    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status == AuthenticationStatus.authenticated) {
      final uid = authState.user.id;
      final debateDoc = _firestore
          .collection('users')
          .doc(uid)
          .collection('debates')
          .doc(widget.debateId);
      
      debateDoc.update({
        'response': '$_fullTranscript $textChunks',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
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
      // responseFormat: debateResponseFormate,
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
          'type': c.type,
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
    _isListeningController.close();
    _transcriptionScrollController.dispose();
    _claimsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a mobile/small device
    final isSmallScreen = context.width <= DeviceType.ipad.getMaxWidth();
    final theme = Theme.of(context);
    
    return SelectionArea(
      child: Scaffold(
        appBar: FactCheckAppBar(
          title: 'Debate Analysis',
          subtitle: widget.topic,
          onInfoPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('About This Debate'),
                content: Text('Topic: ${widget.topic}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isSmallScreen 
                  ? _buildVerticalLayout()
                  : _buildHorizontalLayout(),
            ),
          ),
        ),
        floatingActionButton: RecordingFAB(
          isListeningStream: _isListeningController.stream,
          onStartListening: _startListening,
          onStopListening: _stopListening,
        ),
      ),
    );
  }

  Widget _buildVerticalLayout() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          constraints: BoxConstraints(
            maxHeight: context.height * 0.25,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live Transcription',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      StreamBuilder<bool>(
                        stream: _isListeningController.stream,
                        initialData: false,
                        builder: (context, snapshot) {
                          final isListening = snapshot.data ?? false;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isListening 
                                  ? theme.colorScheme.errorContainer 
                                  : theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isListening ? Icons.mic : Icons.mic_off,
                                  size: 16,
                                  color: isListening 
                                      ? theme.colorScheme.onErrorContainer 
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isListening ? 'Recording' : 'Not Recording',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isListening 
                                        ? theme.colorScheme.onErrorContainer 
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      controller: _transcriptionScrollController,
                      child: _buildTranscriptionStream(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Parsed debate-claims list - takes remaining space
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fact_check,
                          color: theme.colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fact Checks',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: _buildClaimsList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Topic header
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.topic,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live transcription - takes 40% of width
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                            border: Border(
                              bottom: BorderSide(
                                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.record_voice_over,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Live Transcription',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Spacer(),
                              StreamBuilder<bool>(
                                stream: _isListeningController.stream,
                                initialData: false,
                                builder: (context, snapshot) {
                                  final isListening = snapshot.data ?? false;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isListening 
                                          ? theme.colorScheme.errorContainer 
                                          : theme.colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isListening ? Icons.mic : Icons.mic_off,
                                          size: 16,
                                          color: isListening 
                                              ? theme.colorScheme.onErrorContainer 
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isListening ? 'Recording' : 'Not Recording',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: isListening 
                                                ? theme.colorScheme.onErrorContainer 
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              controller: _transcriptionScrollController,
                              child: _buildTranscriptionStream(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Parsed debate-claims list - takes 60% of width
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                            border: Border(
                              bottom: BorderSide(
                                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fact_check,
                                color: theme.colorScheme.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fact Checks',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                        // Content
                        Expanded(
                          child: _buildClaimsList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // New method to build the transcription stream from Firebase
  Widget _buildTranscriptionStream() {
    final theme = Theme.of(context);
    
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(uid)
          .collection('debates')
          .doc(widget.debateId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: TextStyle(color: theme.colorScheme.error),
          );
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text(
            '🎙️ Tap the mic button and start speaking...',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }
        
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final response = data?['response'] as String? ?? '';
        
        // Schedule a scroll to bottom when new data arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_transcriptionScrollController.hasClients) {
            _transcriptionScrollController.animateTo(
              _transcriptionScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        
        return Text(
          '🎙️ $response',
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurface,
          ),
        );
      },
    );
  }

  Widget _buildClaimsList() {
    final theme = Theme.of(context);
    
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(uid)
          .collection('debates')
          .doc(widget.debateId)
          .collection('claims')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          );
        }
        
        if (!snap.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.secondary,
            ),
          );
        }
        
        final docs = snap.data!.docs;
        
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No fact checks yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start speaking to generate fact checks',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.separated(
          controller: _claimsScrollController,
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final claim = Claims(
              claim: data['claim'] as String?,
              rating: data['rating'] as String?,
              type: data['type'] as String?,
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
    );
  }

  // Add this helper if you like:
  Widget _buildClaimBubble(Claims claim, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isFor = claim.type == 'FOR';
    
    // More vibrant colors for the bubbles
    final bgColor = isFor 
        ? theme.colorScheme.primaryContainer.withOpacity(0.7)
        : theme.colorScheme.errorContainer.withOpacity(0.7);
    
    final textColor = isFor
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;
        
    final ratingColor = isFor
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
        
    final radius = BorderRadius.circular(16);

    return Column(
      crossAxisAlignment: isFor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rating chip
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: ratingColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ratingColor.withOpacity(0.3)),
          ),
          child: Text(
            claim.rating ?? '',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ratingColor,
            ),
          ),
        ),
        
        // Explanation bubble
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: isFor ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isFor) 
                Icon(Icons.link, color: theme.colorScheme.error),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isFor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        claim.explanation ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isFor) 
                Icon(Icons.link, color: theme.colorScheme.primary),
            ],
          ),
        ),

        // Claim text
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            claim.claim ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
      ],
    );
  }
}
