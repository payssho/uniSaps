import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'widgets/widget_sync_listener.dart';

class UniSapsApp extends ConsumerWidget {
  const UniSapsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final localeState = ref.watch(localeProvider);

    if (localeState.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return WidgetSyncListener(
      child: MaterialApp.router(
        title: 'uniSaps',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: localeState.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    );
  }
}
