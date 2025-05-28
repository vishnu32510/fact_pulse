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
import 'package:fact_pulse/core/widgets/fact_check_app_bar.dart';
import 'package:fact_pulse/core/widgets/live_transcription_panel.dart';
import 'package:fact_pulse/core/widgets/recording_fab.dart';

class SpeechScreen extends StatefulWidget {
  final String speechId;
  final String topic;
  const SpeechScreen({super.key, required this.speechId, required this.topic});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  late stt.SpeechToText _speech;
  late PerplexityClient _client;
  late final String uid;
  String _fullTranscript = '';
  String textChunks = "";

  final _transcriptionController = StreamController<String>.broadcast();
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupSpeechDoc());
  }

  Future<void> _setupSpeechDoc() async {
    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status != AuthenticationStatus.authenticated) return;
    final uid = authState.user.id;
    final debateDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('speechs')
        .doc(widget.speechId);

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
    textChunks = result.recognizedWords;
    _transcriptionController.add('$_fullTranscript $textChunks');
    if (textChunks.split(' ').length % 7 == 0) {
      _queryFactCheck('$_fullTranscript $textChunks');
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
        .collection('speechs')
        .doc(widget.speechId);

    final systemPrompt = loadSpeechSystemPrompt(topic: widget.topic);
    final request = ChatRequestModel.defaultRequest(
      systemPrompt: systemPrompt,
      prompt: prompt,
      stream: false,
      model: PerplexityModel.sonar,
      // responseFormat: generalResponseFormate
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
    _isListeningController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);
    
    return SelectionArea(
      child: Scaffold(
        appBar: FactCheckAppBar(
          title: 'Speech Analysis',
          subtitle: widget.topic,
          onInfoPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('About This Speech'),
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
        LiveTranscriptionPanel(
          transcriptionStream: _transcriptionController.stream,
          isListeningStream: _isListeningController.stream,
          maxHeight: MediaQuery.of(context).size.height * 0.25,
        ),
        
        const SizedBox(height: 16),
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
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('users')
                          .doc(uid)
                          .collection('speechs')
                          .doc(widget.speechId)
                          .collection('claims')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (ctx, snap) {
                        if (snap.hasError) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: theme.colorScheme.error,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading fact checks',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${snap.error}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.error.withOpacity(0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final docs = snap.data!.docs;
                        
                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fact_check,
                                  size: 48,
                                  color: theme.colorScheme.secondary.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No fact checks yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
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
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            final claim = Claims(
                              claim: data['claim'] as String?,
                              rating: data['rating'] as String?,
                              explanation: data['explanation'] as String?,
                              sources: (data['sources'] as List<dynamic>?)?.cast<String>(),
                            );
                            return _buildClaimCard(claim, theme);
                          },
                        );
                      },
                    ),
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
                child: LiveTranscriptionPanel(
                  transcriptionStream: _transcriptionController.stream,
                  isListeningStream: _isListeningController.stream,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Parsed speech-claims list - takes 60% of width
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
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('users')
                                .doc(uid)
                                .collection('speechs')
                                .doc(widget.speechId)
                                .collection('claims')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (ctx, snap) {
                              if (snap.hasError) {
                                return Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: theme.colorScheme.error,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Error loading fact checks',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${snap.error}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.error.withOpacity(0.8),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              if (!snap.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              final docs = snap.data!.docs;
                              
                              if (docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.fact_check,
                                        size: 48,
                                        color: theme.colorScheme.secondary.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No fact checks yet',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        textAlign: TextAlign.center,
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
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (ctx, i) {
                                  final data = docs[i].data() as Map<String, dynamic>;
                                  final claim = Claims(
                                    claim: data['claim'] as String?,
                                    rating: data['rating'] as String?,
                                    explanation: data['explanation'] as String?,
                                    sources: (data['sources'] as List<dynamic>?)?.cast<String>(),
                                  );
                                  return _buildClaimCard(claim, theme);
                                },
                              );
                            },
                          ),
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

  Widget _buildClaimCard(Claims claim, ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating chip
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRatingColor(claim.rating, theme).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getRatingColor(claim.rating, theme).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                claim.rating ?? 'Unknown',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getRatingColor(claim.rating, theme),
                ),
              ),
            ),
            
            // Claim text
            Text(
              claim.claim ?? 'No claim provided',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Explanation
            Text(
              claim.explanation ?? 'No explanation provided',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            
            // Sources section
            if (claim.sources != null && claim.sources!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sources',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (int i = 0; i < claim.sources!.length; i++)
                    ActionChip(
                      avatar: Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Source ${i + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.4),
                      onPressed: () {
                        CustomBottomSheet().showLinksSheet(
                          context, 
                          [claim.sources![i]],
                        );
                      },
                    ),
                ],
              ),
            ],
            
            // View all sources button
            if (claim.sources != null && claim.sources!.length > 1) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(
                    Icons.fact_check,
                    size: 16,
                  ),
                  label: Text('View All Sources'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    CustomBottomSheet().showLinksSheet(context, claim.sources ?? []);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to determine color based on rating
  Color _getRatingColor(String? rating, ThemeData theme) {
    if (rating == null) return theme.colorScheme.outline;
    
    final lowerRating = rating.toLowerCase();
    
    if (lowerRating.contains('true') || 
        lowerRating.contains('mostly true') ||
        lowerRating.contains('accurate')) {
      return Colors.green;
    } else if (lowerRating.contains('false') || 
               lowerRating.contains('misleading') ||
               lowerRating.contains('inaccurate')) {
      return theme.colorScheme.error;
    } else if (lowerRating.contains('mixed') || 
               lowerRating.contains('partly') ||
               lowerRating.contains('needs context')) {
      return Colors.orange;
    } else if (lowerRating.contains('unverified') || 
               lowerRating.contains('uncertain')) {
      return Colors.grey;
    }
    
    return theme.colorScheme.secondary;
  }
}
