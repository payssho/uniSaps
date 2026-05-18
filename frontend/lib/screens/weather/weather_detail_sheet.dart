import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/weather_catalog.dart';
import '../../models/daily_weather_summary.dart';
import '../../providers/weather_provider.dart';
import '../../services/weather_service.dart';

/// Feuille détaillée météo du jour pour la **position actuelle**.
///
/// Affichage original :
/// - en-tête en dégradé selon la météo et le moment de la journée,
/// - bloc « maintenant » avec température + ressenti + ville,
/// - arc soleil/lune indiquant le moment courant,
/// - timeline horizontale 24 h (température + probabilité de pluie),
/// - chips météo (orage, pluie, etc.) et stats utiles (vent / humidité).
class WeatherDetailSheet extends ConsumerStatefulWidget {
  const WeatherDetailSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const WeatherDetailSheet(),
    );
  }

  @override
  ConsumerState<WeatherDetailSheet> createState() => _WeatherDetailSheetState();
}

class _WeatherDetailSheetState extends ConsumerState<WeatherDetailSheet> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    // À l'ouverture on relance toujours un fetch pour avoir la météo de la
    // position courante (utilisateur a pu changer de ville depuis ce matin).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(todayWeatherFetchProvider);
    });
  }

  Future<void> _manualRefresh() async {
    setState(() => _refreshing = true);
    ref.invalidate(todayWeatherFetchProvider);
    try {
      await ref.read(todayWeatherFetchProvider.future);
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final asyncWeather = ref.watch(todayWeatherFetchProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            color: AppColors.canvas,
            child: asyncWeather.when(
              loading: () => _WeatherLoading(scrollController: scrollController),
              error: (_, __) => _WeatherErrorView(
                scrollController: scrollController,
                onRetry: _manualRefresh,
              ),
              data: (fetch) {
                final w = fetch.weather;
                if (w == null) {
                  return _WeatherErrorView(
                    scrollController: scrollController,
                    onRetry: _manualRefresh,
                    detail: fetch.message,
                  );
                }
                return _WeatherDetailContent(
                  fetch: fetch,
                  weather: w,
                  scrollController: scrollController,
                  refreshing: _refreshing,
                  onRefresh: _manualRefresh,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Contenu principal
// ---------------------------------------------------------------------------
class _WeatherDetailContent extends StatelessWidget {
  final WeatherFetchResult fetch;
  final DailyWeatherSummary weather;
  final ScrollController scrollController;
  final bool refreshing;
  final VoidCallback onRefresh;

  const _WeatherDetailContent({
    required this.fetch,
    required this.weather,
    required this.scrollController,
    required this.refreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDay = weather.currentIsDay ?? _isDaytime(weather);
    final tags = WeatherTagKeys.dayContext(
      weatherCode: weather.currentWeatherCode ?? weather.weatherCode,
      tempMin: weather.tempMin,
      tempMax: weather.tempMax,
    );
    final gradient = _weatherGradient(tags, isDay);

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        _Header(
          fetch: fetch,
          weather: weather,
          isDay: isDay,
          gradient: gradient,
          refreshing: refreshing,
          onRefresh: onRefresh,
        ),
        const SizedBox(height: 16),
        _HourlyTimelineCard(weather: weather),
        const SizedBox(height: 14),
        _StatsCard(weather: weather),
        const SizedBox(height: 14),
        _RainSummaryCard(weather: weather),
        const SizedBox(height: 14),
        _SunArcCard(weather: weather),
        const SizedBox(height: 24),
        _FooterMeta(weather: weather, fetch: fetch),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// En-tête (dégradé + ville + temp courante + min/max)
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final WeatherFetchResult fetch;
  final DailyWeatherSummary weather;
  final bool isDay;
  final List<Color> gradient;
  final bool refreshing;
  final VoidCallback onRefresh;

  const _Header({
    required this.fetch,
    required this.weather,
    required this.isDay,
    required this.gradient,
    required this.refreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final currentCode = weather.currentWeatherCode ?? weather.weatherCode;
    final visual = WeatherTagKeys.visualFor(
      WeatherTagKeys.fromWmoCode(currentCode),
    );
    final temp = (weather.currentTemperatureC ??
            ((weather.tempMin + weather.tempMax) / 2))
        .round();
    final apparent = weather.currentApparentTemperatureC?.round();
    final minMax = formatTempRange(weather.tempMin, weather.tempMax);
    final city = weather.cityName.isNotEmpty
        ? weather.cityName
        : (fetch.usedFallbackLocation ? 'Paris (approx.)' : 'Position');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: _AmbientOrb(color: gradient.last.withOpacity(0.35), size: 220),
          ),
          Positioned(
            bottom: -60,
            left: -50,
            child:
                _AmbientOrb(color: gradient.first.withOpacity(0.30), size: 180),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 18,
                          color: AppColors.white.withOpacity(0.92)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: refreshing ? null : onRefresh,
                        icon: refreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded,
                                color: AppColors.white),
                        tooltip: 'Actualiser à ma position',
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close, color: AppColors.white),
                        tooltip: 'Fermer',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$temp°',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 76,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(visual.icon,
                                    color: AppColors.white, size: 22),
                                const SizedBox(width: 6),
                                Text(
                                  visual.shortLabel,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Auj. $minMax',
                              style: TextStyle(
                                color: AppColors.white.withOpacity(0.92),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            if (apparent != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Ressenti $apparent°',
                                style: TextStyle(
                                  color: AppColors.white.withOpacity(0.92),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _AmbientOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arc soleil / lune : montre où on en est dans la journée
// ---------------------------------------------------------------------------
class _SunArcCard extends StatelessWidget {
  final DailyWeatherSummary weather;

  const _SunArcCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sunrise = weather.sunrise ??
        DateTime(now.year, now.month, now.day, 7, 0);
    final sunset =
        weather.sunset ?? DateTime(now.year, now.month, now.day, 20, 0);
    final isDay = !(now.isBefore(sunrise) || now.isAfter(sunset));
    final progress = _progressBetween(now, sunrise, sunset).clamp(0.0, 1.0);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: isDay
                ? Icons.wb_sunny_outlined
                : Icons.nights_stay_outlined,
            label: isDay ? 'Course du soleil' : 'Nuit en cours',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _SunArcPainter(
                progress: progress,
                isDay: isDay,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TimeLabel(
                icon: Icons.wb_twilight_rounded,
                label: 'Lever',
                value: _fmtTime(sunrise),
              ),
              _TimeLabel(
                icon: Icons.nightlight_round,
                label: 'Coucher',
                value: _fmtTime(sunset),
                alignEnd: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

double _progressBetween(DateTime now, DateTime start, DateTime end) {
  if (now.isBefore(start)) return 0;
  if (now.isAfter(end)) return 1;
  final total = end.difference(start).inSeconds;
  if (total <= 0) return 0;
  return now.difference(start).inSeconds / total;
}

class _SunArcPainter extends CustomPainter {
  final double progress;
  final bool isDay;
  _SunArcPainter({required this.progress, required this.isDay});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 4, size.width - 16, size.height * 2 - 16);
    final start = math.pi;
    final sweep = math.pi;

    final bg = Paint()
      ..color = AppColors.divider.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, bg);

    final fg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: isDay
            ? [const Color(0xFFFFB74D), const Color(0xFFFF7043)]
            : [AppColors.yaleBlue, AppColors.stormyTeal],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep * progress, false, fg);

    // Petit disque qui suit la course
    final angle = start + sweep * progress;
    final cx = rect.center.dx + (rect.width / 2) * math.cos(angle);
    final cy = rect.center.dy + (rect.height / 2) * math.sin(angle);
    final dot = Paint()
      ..color = isDay ? const Color(0xFFFFC107) : AppColors.white;
    canvas.drawCircle(Offset(cx, cy), 8, dot);
    final ring = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), 8, ring);
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDay != isDay;
  }
}

class _TimeLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool alignEnd;
  const _TimeLabel({
    required this.icon,
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                )),
          ],
        ),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline 24 h
// ---------------------------------------------------------------------------
class _HourlyTimelineCard extends StatefulWidget {
  final DailyWeatherSummary weather;
  const _HourlyTimelineCard({required this.weather});

  @override
  State<_HourlyTimelineCard> createState() => _HourlyTimelineCardState();
}

class _HourlyTimelineCardState extends State<_HourlyTimelineCard> {
  static const double _kPillWidth = 60;
  static const double _kPillSpacing = 6;
  static const double _kListHPad = 2;

  final ScrollController _controller = ScrollController();
  bool _centered = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _centerOnNow(int nowIndex, int total) {
    if (_centered || !_controller.hasClients) return;
    _centered = true;
    final viewport = _controller.position.viewportDimension;
    final pillStride = _kPillWidth + _kPillSpacing;
    final targetCenter = _kListHPad + pillStride * nowIndex + _kPillWidth / 2;
    final offset = (targetCenter - viewport / 2)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours = _todayHours(widget.weather);
    if (hours.isEmpty) {
      return _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SectionTitle(
              icon: Icons.timeline_rounded,
              label: 'Heure par heure',
            ),
            SizedBox(height: 12),
            Text('Données horaires indisponibles.',
                style: AppTextStyles.caption),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final tempMin = hours.map((e) => e.temperatureC).reduce(math.min);
    final tempMax = hours.map((e) => e.temperatureC).reduce(math.max);

    int nowIndex = hours.indexWhere((p) =>
        p.time.hour == now.hour &&
        p.time.day == now.day &&
        p.time.month == now.month);
    if (nowIndex < 0) {
      nowIndex = hours.indexWhere((p) => !p.time.isBefore(now));
      if (nowIndex < 0) nowIndex = hours.length - 1;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _centerOnNow(nowIndex, hours.length);
    });

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.timeline_rounded,
            label: 'Heure par heure',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 168,
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _kListHPad),
              itemBuilder: (_, i) {
                final p = hours[i];
                final isNow = i == nowIndex;
                final t = (tempMax == tempMin)
                    ? 0.5
                    : (p.temperatureC - tempMin) / (tempMax - tempMin);
                return SizedBox(
                  width: _kPillWidth,
                  child: _HourPillar(
                    point: p,
                    normalized: t.clamp(0.0, 1.0),
                    isNow: isNow,
                  ),
                );
              },
              separatorBuilder: (_, __) =>
                  const SizedBox(width: _kPillSpacing),
              itemCount: hours.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _HourPillar extends StatelessWidget {
  final HourlyWeatherPoint point;
  final double normalized;
  final bool isNow;
  const _HourPillar({
    required this.point,
    required this.normalized,
    required this.isNow,
  });

  @override
  Widget build(BuildContext context) {
    final tags = WeatherTagKeys.fromWmoCode(point.weatherCode);
    final visual = WeatherTagKeys.visualFor(tags);
    final pop = point.precipitationProbabilityPct;
    final showRain = pop >= 20;
    final hour = point.time.hour.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: isNow ? AppColors.accent.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isNow
            ? Border.all(color: AppColors.accent.withOpacity(0.5), width: 1.2)
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        children: [
          Text(
            isNow ? "Now" : "${hour}h",
            style: TextStyle(
              fontSize: 11,
              fontWeight: isNow ? FontWeight.w800 : FontWeight.w600,
              color: isNow ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            visual.icon,
            size: 22,
            color: _hourIconColor(point, tags),
          ),
          const SizedBox(height: 8),
          Text(
            '${point.temperatureC.round()}°',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Mini-barre de hauteur proportionnelle à la température
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: AppColors.divider.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  heightFactor: 0.20 + 0.80 * normalized,
                  child: Container(
                    width: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.stormyTeal,
                          AppColors.yaleBlue,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (showRain)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.water_drop,
                    size: 11, color: AppColors.yaleBlue),
                const SizedBox(width: 2),
                Text(
                  '$pop%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.yaleBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

Color _hourIconColor(HourlyWeatherPoint p, Set<String> tags) {
  if (tags.contains(WeatherTagKeys.thunderstorm)) {
    return AppColors.notificationBadge;
  }
  if (tags.contains(WeatherTagKeys.snow)) return AppColors.yaleBlue;
  if (tags.contains(WeatherTagKeys.rain) ||
      tags.contains(WeatherTagKeys.drizzle)) {
    return AppColors.yaleBlue;
  }
  if (tags.contains(WeatherTagKeys.fog) ||
      tags.contains(WeatherTagKeys.cloudy)) {
    return AppColors.textSecondary;
  }
  if (!p.isDay) return AppColors.yaleBlue;
  return const Color(0xFFFFA000);
}

// ---------------------------------------------------------------------------
// Stats : ressenti / vent / humidité
// ---------------------------------------------------------------------------
class _StatsCard extends StatelessWidget {
  final DailyWeatherSummary weather;
  const _StatsCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final apparent = weather.currentApparentTemperatureC?.round();
    final wind = weather.currentWindSpeedKmh?.round();
    final humidity = weather.currentRelativeHumidityPct;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.insights_rounded,
            label: 'En ce moment',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.thermostat_rounded,
                  label: 'Ressenti',
                  value: apparent != null ? '$apparent°' : '-',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.air_rounded,
                  label: 'Vent',
                  value: wind != null ? '$wind km/h' : '-',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidité',
                  value: humidity != null ? '$humidity %' : '-',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Récap pluie
// ---------------------------------------------------------------------------
class _RainSummaryCard extends StatelessWidget {
  final DailyWeatherSummary weather;
  const _RainSummaryCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final hours = _todayHours(weather);
    if (hours.isEmpty) return const SizedBox.shrink();

    final maxPop =
        hours.map((e) => e.precipitationProbabilityPct).fold<int>(0, math.max);
    final totalMm = hours
        .map((e) => e.precipitationMm)
        .fold<double>(0, (a, b) => a + b);
    final rainyHours = hours.where((e) => e.precipitationProbabilityPct >= 40);

    final String message;
    final IconData icon;
    final Color color;
    if (totalMm < 0.1 && maxPop < 20) {
      message = 'Aucune pluie prévue aujourd\'hui.';
      icon = Icons.wb_sunny_outlined;
      color = const Color(0xFFFFA000);
    } else if (rainyHours.isEmpty) {
      message = 'Risque modéré de pluie (max $maxPop %).';
      icon = Icons.grain_rounded;
      color = AppColors.stormyTeal;
    } else {
      final firstRainy = rainyHours.first.time;
      message =
          'Pluie probable à partir de ${_fmtTime(firstRainy)} (max $maxPop %, ~${totalMm.toStringAsFixed(1)} mm).';
      icon = Icons.umbrella_rounded;
      color = AppColors.yaleBlue;
    }

    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer : ville + maj
// ---------------------------------------------------------------------------
class _FooterMeta extends StatelessWidget {
  final DailyWeatherSummary weather;
  final WeatherFetchResult fetch;
  const _FooterMeta({required this.weather, required this.fetch});

  @override
  Widget build(BuildContext context) {
    final updated = _fmtTime(weather.fetchedAt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_outlined,
              size: 13, color: AppColors.textHint),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              fetch.usedFallbackLocation
                  ? 'Position approximative - mis à jour à $updated'
                  : 'Données Open-Meteo - mis à jour à $updated',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loader / erreur
// ---------------------------------------------------------------------------
class _WeatherLoading extends StatelessWidget {
  final ScrollController scrollController;
  const _WeatherLoading({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      children: [
        const SizedBox(height: 80),
        const Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(),
          ),
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'Localisation et récupération de la météo…',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherErrorView extends StatelessWidget {
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final String? detail;
  const _WeatherErrorView({
    required this.scrollController,
    required this.onRetry,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      children: [
        Icon(Icons.cloud_off_rounded,
            size: 48, color: AppColors.textHint.withOpacity(0.6)),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Impossible de récupérer la météo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (detail != null && detail!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.graphite.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

List<HourlyWeatherPoint> _todayHours(DailyWeatherSummary weather) {
  if (weather.hourly.isEmpty) return const [];
  final target = weather.date;
  final today = DateTime(target.year, target.month, target.day);
  final tomorrow = today.add(const Duration(days: 1));
  return weather.hourly
      .where((h) => !h.time.isBefore(today) && h.time.isBefore(tomorrow))
      .toList();
}

bool _isDaytime(DailyWeatherSummary w) {
  final now = DateTime.now();
  if (w.sunrise == null || w.sunset == null) {
    final h = now.hour;
    return h >= 7 && h < 21;
  }
  return now.isAfter(w.sunrise!) && now.isBefore(w.sunset!);
}

String _fmtTime(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '${h}h$m';
}

List<Color> _weatherGradient(Set<String> tags, bool isDay) {
  if (tags.contains(WeatherTagKeys.thunderstorm)) {
    return const [Color(0xFF2C3E50), Color(0xFF1A1F2B)];
  }
  if (tags.contains(WeatherTagKeys.snow)) {
    return const [Color(0xFF7EA0B5), Color(0xFFB8CFDE)];
  }
  if (tags.contains(WeatherTagKeys.rain) ||
      tags.contains(WeatherTagKeys.drizzle)) {
    return const [Color(0xFF3B5673), Color(0xFF5C7A9B)];
  }
  if (tags.contains(WeatherTagKeys.fog)) {
    return const [Color(0xFF7C8896), Color(0xFFB1BAC2)];
  }
  if (!isDay) {
    return const [Color(0xFF1B2A4E), Color(0xFF3C507A)];
  }
  if (tags.contains(WeatherTagKeys.cloudy)) {
    return const [Color(0xFF6E8AA5), Color(0xFF9BB2C7)];
  }
  if (tags.contains(WeatherTagKeys.partlyCloudy)) {
    return const [Color(0xFF3C6E71), Color(0xFFFFB347)];
  }
  // Beau temps par défaut
  return const [Color(0xFFFF9A3D), Color(0xFFFFC773)];
}
