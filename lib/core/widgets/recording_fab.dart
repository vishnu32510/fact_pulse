import 'package:flutter/material.dart';

class RecordingFAB extends StatelessWidget {
  final Stream<bool> isListeningStream;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final String? startLabel;
  final String? stopLabel;

  const RecordingFAB({
    super.key,
    required this.isListeningStream,
    required this.onStartListening,
    required this.onStopListening,
    this.startLabel,
    this.stopLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return StreamBuilder<bool>(
      stream: isListeningStream,
      initialData: false,
      builder: (ctx, snap) {
        final isListening = snap.data!;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isListening 
                    ? theme.colorScheme.error.withOpacity(0.3)
                    : theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: isListening ? onStopListening : onStartListening,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isListening ? Icons.stop_circle : Icons.mic,
                key: ValueKey<bool>(isListening),
              ),
            ),
            label: Text(isListening 
                ? (stopLabel ?? 'Stop Recording') 
                : (startLabel ?? 'Start Recording')),
            backgroundColor: isListening 
                ? theme.colorScheme.errorContainer 
                : theme.colorScheme.primaryContainer,
            foregroundColor: isListening 
                ? theme.colorScheme.onErrorContainer 
                : theme.colorScheme.onPrimaryContainer,
            elevation: 0,
          ),
        );
      },
    );
  }
}