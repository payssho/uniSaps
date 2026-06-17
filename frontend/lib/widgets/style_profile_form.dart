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
  final bool showPreferredStyles;
  final bool showUsageFrequency;
  final bool showSocialIntent;

  const StyleProfileForm({
    super.key,
    required this.profile,
    required this.onChanged,
    this.showGoals = true,
    this.showIdentity = true,
    this.showComfort = true,
    this.showPreferredStyles = false,
    this.showUsageFrequency = false,
    this.showSocialIntent = false,
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
            (v) => onChanged(profile.copyWith(goalWardrobe: v)),
          ),
          _goalSlider(
            context,
            l10n.styleGoalInspiration,
            profile.goalInspiration,
            (v) => onChanged(profile.copyWith(goalInspiration: v)),
          ),
          _goalSlider(
            context,
            l10n.styleGoalRefine,
            profile.goalRefineStyle,
            (v) => onChanged(profile.copyWith(goalRefineStyle: v)),
          ),
          _goalSlider(
            context,
            l10n.styleGoalTrack,
            profile.goalTrackWear,
            (v) => onChanged(profile.copyWith(goalTrackWear: v)),
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
                    onChanged(profile.copyWith(identityStyle: key)),
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
                      onChanged(profile.copyWith(audacity: v.round())),
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
          _selectCard(
            context,
            l10n.styleComfortBeginner,
            profile.fashionComfort == 'beginner',
            () => onChanged(profile.copyWith(fashionComfort: 'beginner')),
          ),
          const SizedBox(height: 8),
          _selectCard(
            context,
            l10n.styleComfortBalanced,
            profile.fashionComfort == 'balanced',
            () => onChanged(profile.copyWith(fashionComfort: 'balanced')),
          ),
          const SizedBox(height: 8),
          _selectCard(
            context,
            l10n.styleComfortConfident,
            profile.fashionComfort == 'confident',
            () => onChanged(profile.copyWith(fashionComfort: 'confident')),
          ),
        ],
        if (showPreferredStyles) ...[
          const SizedBox(height: 8),
          Text(l10n.stylePreferredStylesTitle, style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text(
            l10n.stylePreferredStylesHint,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: identityKeys.map((key) {
              final selected = profile.preferredStyles.contains(key);
              return FilterChip(
                label: Text(_identityLabel(context, key)),
                selected: selected,
                onSelected: (on) {
                  final next = List<String>.from(profile.preferredStyles);
                  if (on) {
                    if (!next.contains(key)) next.add(key);
                  } else {
                    next.remove(key);
                  }
                  onChanged(profile.copyWith(preferredStyles: next));
                },
                selectedColor: AppColors.accent.withValues(alpha: 0.25),
                checkmarkColor: AppColors.accent,
              );
            }).toList(),
          ),
        ],
        if (showUsageFrequency) ...[
          const SizedBox(height: 16),
          Text(l10n.styleUsageTitle, style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          _selectCard(
            context,
            l10n.styleUsageDaily,
            profile.usageFrequency == 'daily',
            () => onChanged(profile.copyWith(usageFrequency: 'daily')),
          ),
          const SizedBox(height: 8),
          _selectCard(
            context,
            l10n.styleUsageWeekly,
            profile.usageFrequency == 'weekly',
            () => onChanged(profile.copyWith(usageFrequency: 'weekly')),
          ),
          const SizedBox(height: 8),
          _selectCard(
            context,
            l10n.styleUsageOccasional,
            profile.usageFrequency == 'occasional',
            () => onChanged(profile.copyWith(usageFrequency: 'occasional')),
          ),
        ],
        if (showSocialIntent) ...[
          Text(l10n.styleSocialTitle, style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          _selectCard(
            context,
            l10n.styleSocialFriends,
            profile.socialIntent == 'friends',
            () => onChanged(profile.copyWith(socialIntent: 'friends')),
          ),
          const SizedBox(height: 8),
          _selectCard(
            context,
            l10n.styleSocialPrivate,
            profile.socialIntent == 'private',
            () => onChanged(profile.copyWith(socialIntent: 'private')),
          ),
          const SizedBox(height: 8),
          _selectCard(
            context,
            l10n.styleSocialUndecided,
            profile.socialIntent == 'undecided',
            () => onChanged(profile.copyWith(socialIntent: 'undecided')),
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

  Widget _selectCard(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.12)
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
}
