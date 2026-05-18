import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../providers/auth_provider.dart';
import '../providers/friendship_provider.dart';
import '../providers/garment_provider.dart';
import '../providers/outfit_provider.dart';
import '../providers/post_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/widget_launch_provider.dart';
import '../services/widget_constants.dart';
import '../services/widget_sync_bridge.dart';
import '../services/widget_sync_service.dart';

/// Écoute les données app et déclenche la sync widgets + deep links.
class WidgetSyncListener extends ConsumerStatefulWidget {
  const WidgetSyncListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WidgetSyncListener> createState() => _WidgetSyncListenerState();
}

class _WidgetSyncListenerState extends ConsumerState<WidgetSyncListener>
    with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _clickSub;
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetSyncBridge.attach(ref);
    _clickSub = HomeWidget.widgetClicked.listen(_onWidgetUri);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialWidgetLaunch();
      _scheduleSync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clickSub?.cancel();
    WidgetSyncBridge.detach();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleSync();
    }
  }

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    Future.microtask(() async {
      _syncScheduled = false;
      if (!mounted) return;
      await WidgetSyncService.sync(ref);
    });
  }

  Future<void> _handleInitialWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null) _applyUri(uri);
  }

  void _onWidgetUri(Uri? uri) {
    if (uri != null) _applyUri(uri);
  }

  void _applyUri(Uri uri) {
    final tabParam = uri.queryParameters['tab'] ?? '';
    final tab = _tabIndexFromParam(tabParam);
    final mode = uri.queryParameters['mode'];
    final action = uri.queryParameters['action'];
    ref.read(widgetLaunchRequestProvider.notifier).state = WidgetLaunchRequest(
      tab: tab,
      outfitsSwipeMode:
          mode == 'swipe' || uri.toString() == WidgetDeepLinks.outfitsSwipe,
      openPublish: action == 'publish' || uri.host == 'publish',
    );
  }

  int _tabIndexFromParam(String tab) {
    switch (tab) {
      case 'outfits':
        return 1;
      case 'inspo':
      case 'inspiration':
        return 2;
      case 'profile':
      case 'profil':
        return 3;
      case 'dressing':
        return 0;
      default:
        return int.tryParse(tab)?.clamp(0, 3) ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, __) => _scheduleSync());
    ref.listen(currentUserProvider, (_, __) => _scheduleSync());
    final uid = ref.watch(authServiceProvider).uid;
    if (uid.isNotEmpty) {
      ref.listen(outfitsProvider(uid), (_, __) => _scheduleSync());
      ref.listen(garmentsProvider(uid), (_, __) => _scheduleSync());
    }
    ref.listen(postsProvider, (_, __) => _scheduleSync());
    ref.listen(friendsPostsProvider, (_, __) => _scheduleSync());
    ref.listen(hasPostedTodayProvider, (_, __) => _scheduleSync());
    ref.listen(todayWeatherFetchProvider, (_, __) => _scheduleSync());

    return widget.child;
  }
}
