import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomBottomSheet {
  void showLinksSheet(BuildContext context, List<String> links) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: links.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, index) {
              final link = links[index];
              return ListTile(
                title: Text(
                  link,
                  style: const TextStyle(
                    // color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: () async {
                  final uri = Uri.tryParse(link);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Couldn’t open $link')));
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
