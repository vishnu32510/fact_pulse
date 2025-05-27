import 'package:flutter/material.dart';

class LiveTranscriptionPanel extends StatelessWidget {
  final Stream<String> transcriptionStream;
  final Stream<bool> isListeningStream;
  final ScrollController? scrollController;
  final double? maxHeight;
  final int flex;
  final EdgeInsetsGeometry padding;

  const LiveTranscriptionPanel({
    super.key,
    required this.transcriptionStream,
    required this.isListeningStream,
    this.scrollController,
    this.maxHeight,
    this.flex = 4,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Container(
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
            _buildHeader(context),
            
            // Content
            Expanded(
              child: Container(
                padding: padding,
                child: StreamBuilder<String>(
                  stream: transcriptionStream,
                  builder: (ctx, snap) {
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    
                    // Schedule a scroll to bottom when new data arrives
                    if (scrollController != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (scrollController!.hasClients) {
                          scrollController!.animateTo(
                            scrollController!.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                    
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        snap.data!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    // Apply max height constraint if provided
    if (maxHeight != null) {
      content = Container(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: content,
      );
    }
    
    return content;
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
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
            stream: isListeningStream,
            initialData: false,
            builder: (ctx, snap) {
              final isListening = snap.data!;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isListening 
                      ? theme.colorScheme.tertiary.withOpacity(0.2)
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening 
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isListening ? 'Recording' : 'Idle',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isListening 
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap the mic button to start recording',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}