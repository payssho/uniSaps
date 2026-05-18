import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation demandée par un widget ou deep link `unisaps://`.
class WidgetLaunchRequest {
  final int tab;
  final bool outfitsSwipeMode;
  final bool openPublish;

  const WidgetLaunchRequest({
    required this.tab,
    this.outfitsSwipeMode = false,
    this.openPublish = false,
  });
}

final widgetLaunchRequestProvider =
    StateProvider<WidgetLaunchRequest?>((ref) => null);

/// Incrémenté pour ouvrir le flux « Publier » depuis un widget / deep link.
final inspoPublishTriggerProvider = StateProvider<int>((ref) => 0);
