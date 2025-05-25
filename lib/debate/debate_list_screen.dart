import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fact_pulse/debate/debate_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// 1️⃣ DebatesListScreen
class DebatesListScreen extends StatelessWidget {
  const DebatesListScreen({super.key});

  Future<void> _showCreateDialog(BuildContext context) async {
    final topicCtrl = TextEditingController();
    var saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('New Debate'),
            content: TextField(
              controller: topicCtrl,
              decoration: const InputDecoration(
                labelText: 'Debate topic',
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
                        final debatesRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('debates');
                        final docRef = debatesRef.doc();
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
                                DebateScreen(debateId: docRef.id, topic: topicCtrl.text.trim()),
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
        .collection('debates');

    return Scaffold(
      appBar: AppBar(title: const Text('Your Debates')),
      body: StreamBuilder<QuerySnapshot>(
        stream: debatesRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No debates yet'));
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
                      builder: (_) => DebateScreen(debateId: debateId, topic: topic),
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

// 2️⃣ DebateCreationScreen
class DebateCreationScreen extends StatefulWidget {
  const DebateCreationScreen({super.key});

  @override
  State<DebateCreationScreen> createState() => _DebateCreationScreenState();
}

class _DebateCreationScreenState extends State<DebateCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _createAndOpen() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final debatesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('debates');

    final docRef = debatesRef.doc(); // auto‐ID
    final now = FieldValue.serverTimestamp();

    await docRef.set({
      'topic': _topicCtrl.text.trim(),
      'createdAt': now,
      'response': '',
      'complete': false,
    });

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DebateScreen(debateId: docRef.id, topic: _topicCtrl.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Debate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _topicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Debate topic',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter a topic' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: const Text('Start Debate'),
                onPressed: _saving ? null : _createAndOpen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
