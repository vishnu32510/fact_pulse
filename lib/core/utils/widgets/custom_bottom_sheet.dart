import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomBottomSheet {
  void showLinksSheet(BuildContext context, List<String> links) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Source Links',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${links.length} ${links.length == 1 ? 'link' : 'links'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Links list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: links.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: links.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (ctx, index) {
                        final link = links[index];
                        return _buildLinkTile(ctx, link, theme);
                      },
                    ),
            ),
            
            // Bottom padding for safe area
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLinkTile(BuildContext context, String link, ThemeData theme) {
    final uri = Uri.tryParse(link);
    final isValidUrl = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    
    // Extract domain for display
    String displayText = link;
    if (isValidUrl && uri.host.isNotEmpty) {
      displayText = uri.host;
      if (displayText.startsWith('www.')) {
        displayText = displayText.substring(4);
      }
    }
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isValidUrl 
              ? theme.colorScheme.primaryContainer 
              : theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            isValidUrl ? Icons.language : Icons.link_off,
            color: isValidUrl 
                ? theme.colorScheme.primary 
                : theme.colorScheme.error,
            size: 20,
          ),
        ),
      ),
      title: Text(
        displayText,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        link,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          decoration: isValidUrl ? TextDecoration.underline : null,
          decorationColor: theme.colorScheme.primary.withOpacity(0.5),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isValidUrl
          ? IconButton(
              icon: Icon(
                Icons.open_in_new,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              onPressed: () => _launchUrl(context, link),
            )
          : null,
      onTap: isValidUrl ? () => _launchUrl(context, link) : null,
    );
  }
  
  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No links available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'There are no source links for this claim',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Future<void> _launchUrl(BuildContext context, String link) async {
    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Couldn\'t open $link')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
