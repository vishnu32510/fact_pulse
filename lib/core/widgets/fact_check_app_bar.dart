import 'package:flutter/material.dart';

class FactCheckAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onInfoPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool showLogo;

  const FactCheckAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onInfoPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackground = backgroundColor ?? theme.colorScheme.surface;
    final effectiveForeground = foregroundColor ?? theme.colorScheme.onSurface;
    
    return AppBar(
      title: Row(
        children: [
          if (showLogo) ...[
            Image.asset(
              'assets/icon/icon.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 12),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: subtitle != null ? 16 : 18,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: effectiveForeground.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (onInfoPressed != null)
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: onInfoPressed,
          ),
        if (actions != null) ...actions!,
      ],
      elevation: elevation,
      backgroundColor: effectiveBackground,
      foregroundColor: effectiveForeground,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}