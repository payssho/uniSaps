import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widget_sync_service.dart';

/// Point d'accès pour déclencher une sync widget sans [WidgetRef] (ex. notifiers).
class WidgetSyncBridge {
  WidgetSyncBridge._();

  static WidgetRef? _ref;

  static void attach(WidgetRef ref) => _ref = ref;

  static void detach() => _ref = null;

  static Future<void> request() async {
    final ref = _ref;
    if (ref == null) return;
    await WidgetSyncService.sync(ref);
  }
}
