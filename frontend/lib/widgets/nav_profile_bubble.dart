import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';

/// Bulle photo pour l’onglet Profil (nav utilisateur et créateur).
class NavProfileBubble extends StatelessWidget {
  final bool selected;
  final bool locked;
  final int badgeCount;
  final String photoUrl;
  final String username;
  final VoidCallback onTap;
  final IconData? fallbackIcon;
  final bool tutorialSpotlight;

  const NavProfileBubble({
    super.key,
    required this.selected,
    required this.locked,
    required this.badgeCount,
    required this.photoUrl,
    required this.username,
    required this.onTap,
    this.fallbackIcon,
    this.tutorialSpotlight = false,
  });

  static const double _radius = 15;

  @override
  Widget build(BuildContext context) {
    final borderColor = locked
        ? AppColors.textHint.withValues(alpha: 0.35)
        : tutorialSpotlight || selected
            ? AppColors.accent
            : AppColors.divider.withValues(alpha: 0.9);
    final borderWidth =
        tutorialSpotlight ? 3.0 : (selected ? 2.5 : 1.5);
    final labelColor = locked
        ? AppColors.textHint.withValues(alpha: 0.35)
        : tutorialSpotlight || selected
            ? AppColors.accent
            : AppColors.textHint;

    Widget bubble = Semantics(
      label: 'Profil',
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.all(selected ? 4 : 0),
                    decoration: selected
                        ? BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: borderColor,
                          width: borderWidth,
                        ),
                        boxShadow: tutorialSpotlight || selected
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: tutorialSpotlight ? 0.45 : 0.22,
                                  ),
                                  blurRadius: tutorialSpotlight ? 14 : 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: _radius,
                        backgroundColor: AppColors.surfaceVariant,
                        backgroundImage: photoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? (fallbackIcon != null
                                ? Icon(
                                    fallbackIcon,
                                    size: 18,
                                    color: locked
                                        ? AppColors.textHint.withValues(alpha: 0.45)
                                        : AppColors.primary,
                                  )
                                : Text(
                                    username.isNotEmpty
                                        ? username[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: locked
                                          ? AppColors.textHint.withValues(alpha: 0.45)
                                          : AppColors.textHint,
                                    ),
                                  ))
                            : null,
                      ),
                    ),
                  ),
                  if (locked)
                    Positioned(
                      right: 4,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.graphite.withValues(alpha: 0.08),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lock,
                          size: 9,
                          color: AppColors.textHint.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  if (!locked && badgeCount > 0)
                    Positioned(
                      right: 0,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        constraints:
                            const BoxConstraints(minWidth: 17, minHeight: 17),
                        decoration: BoxDecoration(
                          color: AppColors.notificationBadge,
                          borderRadius: BorderRadius.circular(9),
                          border:
                              Border.all(color: AppColors.surface, width: 1.5),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Profil',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: tutorialSpotlight || selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tutorialSpotlight) {
      bubble = bubble
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.06, 1.06),
            duration: 900.ms,
            curve: Curves.easeInOut,
          );
    }

    return bubble;
  }
}
