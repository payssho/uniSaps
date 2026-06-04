import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../l10n/l10n_context.dart';
import '../models/style_profile.dart';

/// Formulaire partagé onboarding + paramètres.
class StyleProfileForm extends StatelessWidget {
  final StyleProfile profile;
  final ValueChanged<StyleProfile> onChanged;
  final bool showGoals;
  final bool showIdentity;
  final bool showComfort;

  const StyleProfileForm({
    super.key,
    required this.profile,
    required this.onChanged,
    this.showGoals = true,
    this.showIdentity = true,
    this.showComfort = true,
  });

  static const identityKeys = [
    'casual',
    'classic',
    'minimal',
    'streetwear',
    'sport',
    'professional',
    'colorful',
    'evening',
  ];

  String _identityLabel(BuildContext context, String key) {
    final l = context.l10n;
    switch (key) {
      case 'classic':
        return l.styleIdentityClassic;
      case 'minimal':
        return l.styleIdentityMinimal;
      case 'streetwear':
        return l.styleIdentityStreetwear;
      case 'sport':
        return l.styleIdentitySport;
      case 'professional':
        return l.styleIdentityProfessional;
      case 'colorful':
        return l.styleIdentityColorful;
      case 'evening':
        return l.styleIdentityEvening;
      default:
        return l.styleIdentityCasual;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showGoals) ...[
          _goalSlider(
            context,
            l10n.styleGoalWardrobe,
            profile.goalWardrobe,
            (v) => onChanged(_copy(profile, goalWardrobe: v)),
          ),
          _goalSlider(
            context,
            l10n.styleGoalInspiration,
            profile.goalInspiration,
            (v) => onChanged(_copy(profile, goalInspiration: v)),
          ),
          _goalSlider(
            context,
            l10n.styleGoalRefine,
            profile.goalRefineStyle,
            (v) => onChanged(_copy(profile, goalRefineStyle: v)),
          ),
          _goalSlider(
            context,
            l10n.styleGoalTrack,
            profile.goalTrackWear,
            (v) => onChanged(_copy(profile, goalTrackWear: v)),
          ),
          const SizedBox(height: 16),
        ],
        if (showIdentity) ...[
          Text(l10n.styleIdentityTitle, style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: identityKeys.map((key) {
              final selected = profile.identityStyle == key;
              return ChoiceChip(
                label: Text(_identityLabel(context, key)),
                selected: selected,
                onSelected: (_) =>
                    onChanged(_copy(profile, identityStyle: key)),
                selectedColor: AppColors.accent,
                labelStyle: TextStyle(
                  color: selected ? AppColors.white : AppColors.textSecondary,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(l10n.styleAudacity, style: AppTextStyles.bodySecondary),
          Row(
            children: [
              Text(l10n.styleAudacityLow, style: AppTextStyles.caption),
              Expanded(
                child: Slider(
                  value: profile.audacity.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '${profile.audacity}',
                  onChanged: (v) =>
                      onChanged(_copy(profile, audacity: v.round())),
                ),
              ),
              Text(l10n.styleAudacityHigh, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (showComfort) ...[
          Text(l10n.styleComfortTitle, style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          _comfortCard(
            context,
            l10n.styleComfortBeginner,
            'beginner',
            profile.fashionComfort == 'beginner',
            () => onChanged(_copy(profile, fashionComfort: 'beginner')),
          ),
          const SizedBox(height: 8),
          _comfortCard(
            context,
            l10n.styleComfortBalanced,
            'balanced',
            profile.fashionComfort == 'balanced',
            () => onChanged(_copy(profile, fashionComfort: 'balanced')),
          ),
          const SizedBox(height: 8),
          _comfortCard(
            context,
            l10n.styleComfortConfident,
            'confident',
            profile.fashionComfort == 'confident',
            () => onChanged(_copy(profile, fashionComfort: 'confident')),
          ),
        ],
      ],
    );
  }

  Widget _goalSlider(
    BuildContext context,
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySecondary),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$value',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  Widget _comfortCard(
    BuildContext context,
    String label,
    String value,
    bool selected,
    VoidCallback onTap,
  ) {
    return Material(
      color: selected
          ? AppColors.accent.withOpacity(0.12)
          : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.body)),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  StyleProfile _copy(
    StyleProfile p, {
    int? goalWardrobe,
    int? goalInspiration,
    int? goalRefineStyle,
    int? goalTrackWear,
    String? identityStyle,
    int? audacity,
    String? fashionComfort,
    bool? onboardingSkipped,
  }) {
    return StyleProfile(
      goalWardrobe: goalWardrobe ?? p.goalWardrobe,
      goalInspiration: goalInspiration ?? p.goalInspiration,
      goalRefineStyle: goalRefineStyle ?? p.goalRefineStyle,
      goalTrackWear: goalTrackWear ?? p.goalTrackWear,
      identityStyle: identityStyle ?? p.identityStyle,
      audacity: audacity ?? p.audacity,
      fashionComfort: fashionComfort ?? p.fashionComfort,
      onboardingSkipped: onboardingSkipped ?? p.onboardingSkipped,
      updatedAt: p.updatedAt,
    );
  }
}
