import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/weather_catalog.dart';
import '../../models/garment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/garment_provider.dart';
import '../../widgets/storage_aware_cached_image.dart';

IconData _creationWeatherIcon(String id) {
  switch (id) {
    case 'beau':
      return Icons.wb_sunny_rounded;
    case 'nuageux':
      return Icons.cloud_rounded;
    case 'pluie':
      return Icons.umbrella_rounded;
    case 'neige':
      return Icons.ac_unit_rounded;
    default:
      return Icons.wb_cloudy_rounded;
  }
}

IconData _creationSeasonIcon(String key) {
  switch (key) {
    case SeasonKeys.winter:
      return Icons.ac_unit_rounded;
    case SeasonKeys.spring:
      return Icons.eco_rounded;
    case SeasonKeys.summer:
      return Icons.light_mode_rounded;
    case SeasonKeys.autumn:
      return Icons.park_rounded;
    default:
      return Icons.calendar_month_rounded;
  }
}

class CreationScreen extends ConsumerStatefulWidget {
  const CreationScreen({super.key});

  @override
  ConsumerState<CreationScreen> createState() => _CreationScreenState();
}

class _CreationScreenState extends ConsumerState<CreationScreen> {
  final _nameController = TextEditingController();
  final Map<String, String> _selected = {};
  final Map<String, GarmentModel> _selectedGarments = {};
  bool _saving = false;
  String? _referencePhotoUrl;
  bool _uploadingPhoto = false;

  /// Optionnel — vide = toutes saisons pour les suggestions météo.
  final Set<String> _selectedSeasonKeys = {};

  /// Presets temps simples (`WeatherTagKeys.creationSimpleWeatherIds`), optionnel.
  final Set<String> _selectedSimpleWeatherIds = {};

  bool _weatherDropdownOpen = false;
  bool _seasonDropdownOpen = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final uid = ref.read(authServiceProvider).uid;
    if (uid.isEmpty) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 82,
    );
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    final bytes = await picked.readAsBytes();
    final storage = ref.read(storageServiceProvider);
    try {
      final url =
          await storage.uploadOutfitPhotoBytes(bytes, uid, picked.name);
      if (mounted) setState(() => _referencePhotoUrl = url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'upload")),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _showPhotoSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Ajouter la photo de l\'outfit',
                style: AppTextStyles.heading3),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Appareil photo',
                    onTap: () {
                      Navigator.pop(context);
                      _pickPhoto(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(context);
                      _pickPhoto(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickGarment(String zoneKey, String categoryKey) async {
    final uid = ref.read(authServiceProvider).uid;
    final garments = await ref
        .read(firestoreServiceProvider)
        .getGarments(uid, category: categoryKey);
    if (!mounted) return;

    final picked = await showModalBottomSheet<GarmentModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(categoryLabel(categoryKey),
                  style: AppTextStyles.heading3),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: garments.isEmpty
                  ? const Center(
                      child: Text('Aucun vêtement dans cette catégorie',
                          style: AppTextStyles.bodySecondary))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: garments.length,
                      itemBuilder: (_, i) {
                        final g = garments[i];
                        final isSelected = _selected[zoneKey] == g.id;
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, g),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.divider,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    Expanded(
                                      child: g.imageUrl.isNotEmpty
                                          ? StorageAwareCachedImage(
                                              imageUrl: g.imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              loadingWidget: Container(
                                                color: AppColors.surfaceVariant,
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (_, __) =>
                                                  Container(
                                                color:
                                                    AppColors.surfaceVariant,
                                                child: Icon(
                                                  categoryIcon(categoryKey),
                                                  color: AppColors.textHint,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color:
                                                  AppColors.surfaceVariant,
                                              child: Icon(
                                                  categoryIcon(
                                                      categoryKey),
                                                  color:
                                                      AppColors.textHint),
                                            ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.all(5),
                                      child: Text(g.name,
                                          style: const TextStyle(
                                              fontSize: 10),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding:
                                          const EdgeInsets.all(2),
                                      decoration:
                                          const BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: AppColors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _selected[zoneKey] = picked.id;
        _selectedGarments[zoneKey] = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_referencePhotoUrl == null || _referencePhotoUrl!.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('Ajoute la photo de ton outfit.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error.withOpacity(0.96),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            duration: const Duration(seconds: 3),
          ),
        );
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('Donne un nom à ton outfit.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error.withOpacity(0.96),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            duration: const Duration(seconds: 3),
          ),
        );
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('Sélectionne au moins un vêtement.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error.withOpacity(0.96),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            duration: const Duration(seconds: 3),
          ),
        );
      return;
    }
    setState(() {
      _saving = true;
    });

    final uid = ref.read(authServiceProvider).uid;
    final garments = <String, String>{
      'headwear': '',
      'top': '',
      'outerwear': '',
      'bottom': '',
      'shoes': '',
      'accessory': '',
    };
    for (final e in _selected.entries) {
      final cat = bodyZones[e.key] ?? e.key;
      garments[cat] = e.value;
    }

    final id = await ref.read(outfitNotifierProvider.notifier).createOutfit(
          userId: uid,
          name: name,
          garments: garments,
          referencePhotoUrl: _referencePhotoUrl ?? '',
          seasons: _selectedSeasonKeys.toList()..sort(),
          weatherTags: WeatherTagKeys.expandCreationSimplePresets(
              _selectedSimpleWeatherIds),
        );

    if (mounted) {
      setState(() => _saving = false);
      if (id != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Outfit créé !'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: const Text('Erreur lors de la création.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error.withOpacity(0.96),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              duration: const Duration(seconds: 3),
            ),
          );
      }
    }
  }

  String _weatherSummaryText() {
    if (_selectedSimpleWeatherIds.isEmpty) return '';
    return WeatherTagKeys.creationSimpleWeatherIds
        .where(_selectedSimpleWeatherIds.contains)
        .map(WeatherTagKeys.creationSimpleLabelFr)
        .join(', ');
  }

  String _seasonSummaryText() {
    if (_selectedSeasonKeys.isEmpty) return '';
    return SeasonKeys.all
        .where(_selectedSeasonKeys.contains)
        .map(SeasonKeys.labelFr)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final zones = [
      ('head', 'Tête', Icons.face_rounded, 'headwear'),
      ('jacket', 'Veste', Icons.dry_cleaning_rounded, 'outerwear'),
      ('torso', 'Haut', Icons.checkroom_rounded, 'top'),
      ('legs', 'Bas', Icons.accessibility_new_rounded, 'bottom'),
      ('feet', 'Chaussures', Icons.ice_skating_rounded, 'shoes'),
      ('wrist', 'Accessoire', Icons.watch_rounded, 'accessory'),
    ];

    final hasPhoto =
        _referencePhotoUrl != null && _referencePhotoUrl!.isNotEmpty;
    final selectedCount = _selected.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Nouveau look'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accent))
                  : const Text('Sauver',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Photo section (mandatory, prominent) ---
            GestureDetector(
              onTap: _uploadingPhoto ? null : _showPhotoSourcePicker,
              child: Container(
                width: double.infinity,
                height: hasPhoto ? 380 : 220,
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: hasPhoto
                        ? Colors.transparent
                        : AppColors.accent.withOpacity(0.3),
                    width: hasPhoto ? 0 : 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  boxShadow: hasPhoto
                      ? [
                          BoxShadow(
                            color: AppColors.graphite.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: _uploadingPhoto
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(strokeWidth: 2),
                            SizedBox(height: 12),
                            Text('Upload en cours...',
                                style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 13)),
                          ],
                        ),
                      )
                    : hasPhoto
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              StorageAwareCachedImage(
                                imageUrl: _referencePhotoUrl!,
                                fit: BoxFit.cover,
                                loadingWidget: Container(
                                  color: AppColors.surfaceVariant,
                                  child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                ),
                                errorWidget: (_, __) => Container(
                                  color: AppColors.surfaceVariant,
                                  child: Icon(Icons.broken_image_outlined,
                                      color: AppColors.textHint.withOpacity(0.6)),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.graphite.withOpacity(0.5),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_rounded,
                                          size: 14,
                                          color: AppColors.white),
                                      SizedBox(width: 4),
                                      Text('Changer',
                                          style: TextStyle(
                                              color: AppColors.white,
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 28,
                                    color: AppColors.accent),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Ajoute la photo de ton outfit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Obligatoire pour créer un look',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
              ),
            ),

            // --- Name field ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Nom de l\'outfit',
                  prefixIcon: const Icon(Icons.edit_outlined,
                      size: 20, color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // --- Section title ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Pièces du look',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: selectedCount > 0
                          ? AppColors.accent.withOpacity(0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$selectedCount/6',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedCount > 0
                            ? AppColors.accent
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Zone cards ---
            ...zones.asMap().entries.map((entry) {
              final i = entry.key;
              final z = entry.value;
              final (zoneKey, label, icon, catKey) = z;
              final garment = _selectedGarments[zoneKey];
              final hasGarment = garment != null;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Material(
                  color: hasGarment ? AppColors.surface : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _pickGarment(zoneKey, catKey),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasGarment
                              ? AppColors.accent.withOpacity(0.2)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (hasGarment && garment.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: StorageAwareCachedImage(
                                  imageUrl: garment.imageUrl,
                                  fit: BoxFit.cover,
                                  width: 44,
                                  height: 44,
                                  loadingWidget: Container(
                                    color: AppColors.surfaceVariant,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __) => Container(
                                    color: AppColors.surfaceVariant,
                                    child: Icon(
                                      categoryIcon(catKey),
                                      size: 22,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: hasGarment
                                    ? AppColors.surfaceVariant
                                    : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Icon(icon,
                                  size: 20,
                                  color: AppColors.textHint),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasGarment ? garment.name : label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: hasGarment
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: hasGarment
                                        ? AppColors.textPrimary
                                        : AppColors.textHint,
                                  ),
                                ),
                                if (hasGarment &&
                                    garment.brand.isNotEmpty)
                                  Text(garment.brand,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors
                                              .textSecondary)),
                              ],
                            ),
                          ),
                          if (hasGarment)
                            GestureDetector(
                              onTap: () => setState(() {
                                _selected.remove(zoneKey);
                                _selectedGarments.remove(zoneKey);
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.error
                                      .withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 14,
                                    color: AppColors.error),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accent
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded,
                                  size: 14,
                                  color: AppColors.accent),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: (50 * i).ms)
                  .slideX(
                      begin: 0.04,
                      end: 0,
                      duration: 300.ms,
                      delay: (50 * i).ms);
            }),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: _MultiSelectDropdownTile(
                label: 'Temps',
                hintWhenEmpty: 'Toutes les conditions',
                summary: _weatherSummaryText(),
                expanded: _weatherDropdownOpen,
                headerIcon: Icons.cloud_outlined,
                optionIds: WeatherTagKeys.creationSimpleWeatherIds,
                selected: _selectedSimpleWeatherIds,
                labelForKey: WeatherTagKeys.creationSimpleLabelFr,
                iconForKey: _creationWeatherIcon,
                onHeaderTap: () => setState(() {
                  _weatherDropdownOpen = !_weatherDropdownOpen;
                  if (_weatherDropdownOpen) _seasonDropdownOpen = false;
                }),
                onToggleOption: (id) => setState(() {
                  if (_selectedSimpleWeatherIds.contains(id)) {
                    _selectedSimpleWeatherIds.remove(id);
                  } else {
                    _selectedSimpleWeatherIds.add(id);
                  }
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _MultiSelectDropdownTile(
                label: 'Saisons',
                hintWhenEmpty: 'Toutes les saisons',
                summary: _seasonSummaryText(),
                expanded: _seasonDropdownOpen,
                headerIcon: Icons.calendar_today_outlined,
                optionIds: SeasonKeys.all,
                selected: _selectedSeasonKeys,
                labelForKey: SeasonKeys.labelFr,
                iconForKey: _creationSeasonIcon,
                onHeaderTap: () => setState(() {
                  _seasonDropdownOpen = !_seasonDropdownOpen;
                  if (_seasonDropdownOpen) _weatherDropdownOpen = false;
                }),
                onToggleOption: (k) => setState(() {
                  if (_selectedSeasonKeys.contains(k)) {
                    _selectedSeasonKeys.remove(k);
                  } else {
                    _selectedSeasonKeys.add(k);
                  }
                }),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

/// Liste déroulante type sélecteur de couleur : champ + panneau avec icônes (multi-sélection).
class _MultiSelectDropdownTile extends StatelessWidget {
  final String label;
  final String hintWhenEmpty;
  final String summary;
  final bool expanded;
  final IconData headerIcon;
  final List<String> optionIds;
  final Set<String> selected;
  final String Function(String) labelForKey;
  final IconData Function(String) iconForKey;
  final VoidCallback onHeaderTap;
  final void Function(String id) onToggleOption;

  const _MultiSelectDropdownTile({
    required this.label,
    required this.hintWhenEmpty,
    required this.summary,
    required this.expanded,
    required this.headerIcon,
    required this.optionIds,
    required this.selected,
    required this.labelForKey,
    required this.iconForKey,
    required this.onHeaderTap,
    required this.onToggleOption,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = summary.isNotEmpty;
    final display = hasSelection ? summary : hintWhenEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onHeaderTap,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                prefixIcon: Icon(headerIcon,
                    size: 20, color: AppColors.textHint),
                suffixIcon: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textHint,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 4),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: hasSelection
                        ? AppColors.textPrimary
                        : AppColors.textHint.withOpacity(0.95),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 6),
          Material(
            color: AppColors.surface,
            elevation: 2,
            shadowColor: AppColors.graphite.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                children: [
                  for (var i = 0; i < optionIds.length; i++) ...[
                    if (i > 0)
                      Divider(
                          height: 1,
                          thickness: 1,
                          color:
                              AppColors.divider.withOpacity(0.5)),
                    InkWell(
                      onTap: () => onToggleOption(optionIds[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              iconForKey(optionIds[i]),
                              size: 22,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                labelForKey(optionIds[i]),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected
                                          .contains(optionIds[i])
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              selected.contains(optionIds[i])
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 22,
                              color: selected.contains(optionIds[i])
                                  ? AppColors.accent
                                  : AppColors.textHint.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: AppColors.accent),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
