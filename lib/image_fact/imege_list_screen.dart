
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fact_pulse/core/widgets/fact_check_list_view.dart';
import 'package:fact_pulse/image_fact/image_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ImageReportListScreen extends StatelessWidget {
  const ImageReportListScreen({super.key});

  Future<void> _showCreateDialog(BuildContext context) async {
    final topicCtrl = TextEditingController();
    var saving = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('New Image Report'),
            content: TextField(
              controller: topicCtrl,
              decoration: const InputDecoration(
                labelText: 'Image context',
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
                        final imagesRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('images');
                        final docRef = imagesRef.doc();
                        await docRef.set({
                          'topic': topicCtrl.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                          'response': '',
                          'complete': false,
                        });
                        Navigator.of(ctx).pop(); // close dialog
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ImageReportScreen(
                              imageId: docRef.id, 
                              topic: topicCtrl.text.trim(),
                            ),
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

  void _navigateToImageScreen(BuildContext context, String imageId, String topic) {
    // Fetch the image data from Firestore before navigating
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('images')
        .doc(imageId)
        .get()
        .then((doc) {
          if (doc.exists) {
            final data = doc.data()!;
            final List<String> imageData = data['imageData'] != null 
                ? List<String>.from(data['imageData'])
                : [];
                
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ImageReportScreen(
                  imageId: imageId, 
                  topic: topic,
                ),
              ),
            );
          } else {
            // Fallback if no image data is found
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ImageReportScreen(
                  imageId: imageId, 
                  topic: topic,
                ),
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    return FactCheckListView(
      uid: uid,
      collectionName: 'images',
      emptyMessage: 'No Image Reports yet',
      appBarTitle: 'Your Image Reports',
      onItemTap: _navigateToImageScreen,
      onAddPressed: _showCreateDialog,
    );
  }
}
