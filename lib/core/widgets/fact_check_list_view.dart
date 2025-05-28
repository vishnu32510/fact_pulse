import 'package:cloud_firestore/cloud_firestore.dart';
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
          style: TextStyle(
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
          // Header section with count
          StreamBuilder<QuerySnapshot>(
            stream: collectionRef.snapshots(),
            builder: (context, snapshot) {
              final itemCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        collectionIcon,
                        color: accentColor,
                        size: 24,
                      ),
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
                              : '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
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

          // Main list content
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
                    final itemId = docs[i].id;
                    final timestamp = data['createdAt'] as Timestamp?;
                    final date = timestamp?.toDate();
                    final formattedDate = date != null 
                        ? DateFormat('MMM d, yyyy • h:mm a').format(date.toLocal())
                        : 'Date unknown';
                    
                    return _buildListItem(
                      context,
                      itemId,
                      topic,
                      formattedDate,
                      data['complete'] == true,
                      i,
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

  Widget _buildListItem(
    BuildContext context, 
    String id, 
    String title, 
    String date, 
    bool isComplete,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
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
                    if (isComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Complete',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionChip(
                      context, 
                      Icons.visibility, 
                      'View',
                      () => onItemTap(context, id, title),
                    ),
                    _buildActionChip(
                      context, 
                      Icons.picture_as_pdf, 
                      'Generate Report',
                      () => _generateReport(context, id, title),
                    ),
                    _buildActionChip(
                      context, 
                      Icons.delete_outline,
                  'Delete',
                      () => _showDeleteConfirmation(context, id),
                    ),
                    // _buildActionChip(
                    //   context, 
                    //   Icons.more_horiz, 
                    //   'More',
                    //   () {
                    //     _showOptionsBottomSheet(context, id, title);
                    //   },
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context, 
    IconData icon, 
    String label,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, String id, String title) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildOptionTile(
                  context,
                  Icons.edit,
                  'Rename',
                  () {
                    Navigator.pop(context);
                    // TODO: Implement rename functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Rename coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _buildOptionTile(
                  context,
                  Icons.copy,
                  'Duplicate',
                  () {
                    Navigator.pop(context);
                    // TODO: Implement duplicate functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Duplicate coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _buildOptionTile(
                  context,
                  Icons.delete_outline,
                  'Delete',
                  () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, id);
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(color: color),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_getSingularName()}?'),
        content: Text(
          'This action cannot be undone. All associated data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(context, id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context, String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(collectionName)
          .doc(id)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getSingularName()} deleted successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting ${_getSingularName().toLowerCase()}: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
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
            child: Icon(
              collectionIcon,
              size: 64,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            emptyMessage,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create a new ${_getSingularName().toLowerCase()}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => onAddPressed(context),
            icon: const Icon(Icons.add),
            label: Text('Create ${_getSingularName()}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: accentColor),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error Loading Data',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Force refresh by rebuilding the widget
              (context as Element).markNeedsBuild();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSingularName() {
    switch (collectionName) {
      case 'debates':
        return 'Debate';
      case 'speechs':
        return 'Speech';
      case 'images':
        return 'Image Report';
      default:
        return 'Item';
    }
  }

  Future<void> _generateReport(BuildContext context, String itemId, String title) async {
    final theme = Theme.of(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Generating Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Please wait while we generate your report...'),
          ],
        ),
      ),
    );
    
    try {
      // Fetch claims from Firestore
      final claimsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(collectionName)
          .doc(itemId)
          .collection('claims')
          .orderBy('createdAt')
          .get();
      
      // Convert to Claims objects
      final claims = claimsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Claims(
          claim: data['claim'] as String?,
          rating: data['rating'] as String?,
          explanation: data['explanation'] as String?,
          sources: (data['sources'] as List<dynamic>?)?.cast<String>(),
        );
      }).toList();
      
      // Generate the report using the platform-specific implementation
      // The local_report_generator.dart file conditionally exports either
      // local_report_generator_io.dart or local_report_generator_web.dart
      final reportFile = await generateAndSaveReportLocally(
        itemId: itemId,
        claims: claims,
      );
      
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show appropriate success dialog based on platform
      if (kIsWeb) {
        // Web platform: Show simple success message (file already downloaded)
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Report Generated'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text('Your report has been successfully generated.'),
                const SizedBox(height: 8),
                Text(
                  'The report has been downloaded to your device.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('CLOSE'),
              ),
            ],
          ),
        );
      } else {
        // Mobile/Desktop platforms: Show file path and open options
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Report Generated'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text('Your report has been successfully generated.'),
                const SizedBox(height: 8),
                Text(
                  'The report is saved to your device at:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reportFile.path,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('CLOSE'),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.open_in_new),
                label: Text('OPEN'),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final uri = Uri.file(reportFile.path);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open the report'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.share),
                label: Text('SHARE'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // TODO: Implement share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Share functionality coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text('Failed to generate report: ${e.toString()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('CLOSE'),
            ),
          ],
        ),
      );
    }
  }
}
