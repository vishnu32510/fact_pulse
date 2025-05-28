import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fact_pulse/helper/local_report_generator.dart';
import 'package:fact_pulse/helper/local_report_generator_io.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fact_pulse/models/perplexity_response_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FactCheckListView extends StatelessWidget {
  final String uid;
  final String collectionName;
  final String emptyMessage;
  final Function(BuildContext, String, String) onItemTap;
  final String appBarTitle;
  final Function(BuildContext) onAddPressed;
  final IconData collectionIcon;
  final Color accentColor;

  const FactCheckListView({
    super.key,
    required this.uid,
    required this.collectionName,
    required this.emptyMessage,
    required this.onItemTap,
    required this.appBarTitle,
    required this.onAddPressed,
    this.collectionIcon = Icons.fact_check,
    this.accentColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(collectionName);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          // Header
          StreamBuilder<QuerySnapshot>(
            stream: collectionRef.snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(collectionIcon, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Collection',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.connectionState == ConnectionState.waiting
                              ? 'Loading...'
                              : '$count ${count == 1 ? 'item' : 'items'}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: collectionRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return _buildErrorState(context, snap.error.toString());
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState(context);
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data()! as Map<String, dynamic>;
                    final topic = data['topic'] as String? ?? 'Untitled';
                    final id = docs[i].id;
                    final ts = data['createdAt'] as Timestamp?;
                    final date = ts?.toDate();
                    final formatted = date != null
                        ? DateFormat('MMM d, yyyy • h:mm a').format(date.toLocal())
                        : 'Date unknown';
                    return _buildListItem(
                      context, id, topic, formatted, data['complete'] == true, i,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => onAddPressed(context),
        icon: const Icon(Icons.add),
        label: Text('New ${_getSingularName()}'),
        backgroundColor: accentColor,
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String id, String title,
      String date, bool complete, int _) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onItemTap(context, id, title),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (complete)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text('Complete',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _actionChip(context, Icons.visibility, 'View',
                      () => onItemTap(context, id, title)),
                  _actionChip(
                      context,
                      Icons.picture_as_pdf,
                      'Generate Report',
                      () => _generateReport(context, id, title)),
                  _actionChip(context, Icons.delete_outline, 'Delete',
                      () => _showDeleteConfirmation(context, id)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionChip(
      BuildContext c, IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(c);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext ctx, String id) {
    final theme = Theme.of(ctx);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Delete ${_getSingularName()}?'),
        content: const Text(
            'This action cannot be undone. All associated data will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteItem(ctx, id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(BuildContext ctx, String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(collectionName)
          .doc(id)
          .delete();
      ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('${_getSingularName()} deleted')));
    } catch (e) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: Theme.of(ctx).colorScheme.error));
    }
  }

  Widget _buildEmptyState(BuildContext c) {
    final theme = Theme.of(c);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(collectionIcon, size: 64, color: accentColor),
          ),
          const SizedBox(height: 24),
          Text(emptyMessage,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Tap the button below to create a new ${_getSingularName().toLowerCase()}',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => onAddPressed(c),
            icon: const Icon(Icons.add),
            label: Text('Create ${_getSingularName()}'),
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext c) {
    return Center(child: CircularProgressIndicator(color: accentColor));
  }

  Widget _buildErrorState(BuildContext c, String error) {
    final theme = Theme.of(c);
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: theme.colorScheme.error.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
        ),
        const SizedBox(height: 24),
        Text('Error Loading Data',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
        const SizedBox(height: 8),
        Text(error, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 32),
        ElevatedButton.icon(onPressed: () => (c as Element).markNeedsBuild(), icon: const Icon(Icons.refresh), label: const Text('Retry'), style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary)),
      ]),
    );
  }

  String _getSingularName() {
    switch (collectionName) {
      case 'debates': return 'Debate';
      case 'speechs': return 'Speech';
      case 'images': return 'Image Report';
      default: return 'Item';
    }
  }

  Future<void> _generateReport(BuildContext context, String itemId, String title) async {
    final theme = Theme.of(context);
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: Text('Generating Report'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('Please wait while we generate your report...'),
      ]),
    ));
    try {
      final snapshot = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection(collectionName)
        .doc(itemId).collection('claims').orderBy('createdAt').get();
      final claims = snapshot.docs.map((d) => Claims(
        claim: d['claim'], rating: d['rating'], explanation: d['explanation'],
        sources: (d['sources'] as List).cast<String>(),
      )).toList();

      final file = await generateAndSaveReportLocally(itemId: itemId, claims: claims);
      Navigator.of(context).pop();
      if (kIsWeb) {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: Text('Report Generated'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            const SizedBox(height:16),
            Text('Your report has been successfully generated and downloaded.'),
          ]),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('CLOSE'))],
        ));
      } else {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: Text('Report Generated'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            const SizedBox(height:16),
            Text('Your report is saved at:'),
            const SizedBox(height:4),
            Text(file!.path, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('CLOSE')),
            ElevatedButton.icon(icon: Icon(Icons.open_in_new), label: Text('OPEN'), onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.file(file.path);
              await launchUrl(uri);
            }),
          ],
        ));
      }
    } catch (e) {
      Navigator.of(context).pop();
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
          const SizedBox(height:16),
          Text('Failed to generate report: $e'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('CLOSE'))],
      ));
    }
  }
}
