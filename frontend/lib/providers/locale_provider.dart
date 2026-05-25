import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLanguageChoiceCompleted = 'language_choice_completed';
const _kAppLocale = 'app_locale';

/// État de la locale : chargement, choix premier lancement, locale active.
class LocaleState {
  final bool isLoading;
  final bool languageChoiceCompleted;
  final Locale locale;

  const LocaleState({
    required this.isLoading,
    required this.languageChoiceCompleted,
    required this.locale,
  });

  static const initial = LocaleState(
    isLoading: true,
    languageChoiceCompleted: false,
    locale: Locale('fr'),
  );
}

class LocaleNotifier extends StateNotifier<LocaleState> {
  LocaleNotifier() : super(LocaleState.initial) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final completed = _prefs!.getBool(_kLanguageChoiceCompleted) ?? false;
    final saved = _prefs!.getString(_kAppLocale);
    final locale = _resolveLocale(saved, completed);
    state = LocaleState(
      isLoading: false,
      languageChoiceCompleted: completed,
      locale: locale,
    );
  }

  Locale _resolveLocale(String? saved, bool completed) {
    if (saved == 'en') return const Locale('en');
    if (saved == 'fr') return const Locale('fr');
    if (!completed) {
      final sys = ui.PlatformDispatcher.instance.locale.languageCode;
      if (sys == 'en') return const Locale('en');
    }
    return const Locale('fr');
  }

  Future<void> completeFirstLaunchChoice(Locale locale) async {
    _prefs ??= await SharedPreferences.getInstance();
    final code = locale.languageCode == 'en' ? 'en' : 'fr';
    await _prefs!.setBool(_kLanguageChoiceCompleted, true);
    await _prefs!.setString(_kAppLocale, code);
    state = LocaleState(
      isLoading: false,
      languageChoiceCompleted: true,
      locale: Locale(code),
    );
  }

  Future<void> setLocale(Locale locale) async {
    _prefs ??= await SharedPreferences.getInstance();
    final code = locale.languageCode == 'en' ? 'en' : 'fr';
    await _prefs!.setString(_kAppLocale, code);
    if (!state.languageChoiceCompleted) {
      await _prefs!.setBool(_kLanguageChoiceCompleted, true);
    }
    state = state.copyWith(
      languageChoiceCompleted: true,
      locale: Locale(code),
    );
  }
}

extension _LocaleStateCopy on LocaleState {
  LocaleState copyWith({
    bool? isLoading,
    bool? languageChoiceCompleted,
    Locale? locale,
  }) {
    return LocaleState(
      isLoading: isLoading ?? this.isLoading,
      languageChoiceCompleted:
          languageChoiceCompleted ?? this.languageChoiceCompleted,
      locale: locale ?? this.locale,
    );
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, LocaleState>((ref) {
  return LocaleNotifier();
});
