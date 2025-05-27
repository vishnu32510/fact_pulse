import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fact_pulse/speech/speech_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// 1️⃣ SpeechListScreen
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final debatesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('speechs');

    return Scaffold(
      appBar: AppBar(title: const Text('Your Speech')),
      body: StreamBuilder<QuerySnapshot>(
        stream: debatesRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No Speeches yet'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data()! as Map<String, dynamic>;
              final topic = data['topic'] as String? ?? 'Untitled';
              final debateId = docs[i].id;
              return ListTile(
                title: Text(topic),
                subtitle: Text(
                  (data['createdAt'] as Timestamp?)?.toDate().toLocal().toString() ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SpeechScreen(speechId: debateId, topic: topic),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
