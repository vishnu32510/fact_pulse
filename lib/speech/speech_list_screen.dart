import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fact_pulse/core/widgets/fact_check_list_view.dart';
import 'package:fact_pulse/speech/speech_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SpeechListScreen extends StatelessWidget {
  const SpeechListScreen({super.key});

  Future<void> _showCreateDialog(BuildContext context) async {
    final topicCtrl = TextEditingController();
    var saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('New Speech'),
            content: TextField(
              controller: topicCtrl,
              decoration: const InputDecoration(
                labelText: 'Speech topic',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: saving || topicCtrl.text.trim().isEmpty
                    ? null
                    : () async {
                        setState(() => saving = true);
                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final speechsRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('speechs');
                        final docRef = speechsRef.doc();
                        await docRef.set({
                          'topic': topicCtrl.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                          'response': '',
                          'complete': false,
                        });
                        Navigator.of(ctx).pop(); // close dialog
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SpeechScreen(speechId: docRef.id, topic: topicCtrl.text.trim()),
                          ),
                        );
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('CREATE'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToSpeechScreen(BuildContext context, String speechId, String topic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpeechScreen(speechId: speechId, topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    return FactCheckListView(
      uid: uid,
      collectionName: 'speechs',
      emptyMessage: 'No Speeches yet',
      appBarTitle: 'Your Speech',
      onItemTap: _navigateToSpeechScreen,
      onAddPressed: _showCreateDialog,
    );
  }
}
