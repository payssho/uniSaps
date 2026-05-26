import 'package:flutter/material.dart';
import '../app_empty_state.dart';

/// Message vide pour les feeds Inspiration (Amis / Explorer).
class EmptyFeedMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyFeedMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: action,
      size: AppEmptyStateSize.standard,
    );
  }
}
