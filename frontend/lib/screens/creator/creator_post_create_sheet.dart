import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/image_capture.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/categories.dart';
import '../../models/collection_model.dart';
import '../../models/garment_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/creator_post_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../widgets/creator_post_preview_sheet.dart';
import '../../widgets/creation_step_breadcrumb.dart';
import '../../widgets/garment_picker_grid_sheet.dart';
import '../../widgets/storage_aware_cached_image.dart';

class CreatorPostCreateScreen extends ConsumerStatefulWidget {
  const CreatorPostCreateScreen({super.key});

  @override
  ConsumerState<CreatorPostCreateScreen> createState() =>
      _CreatorPostCreateScreenState();
}

class _CreatorPostCreateScreenState extends ConsumerState<CreatorPostCreateScreen> {
  final _nameController = TextEditingController();
  final _captionController = TextEditingController();
  late final FocusNode _nameFocusNode;
  final Map<String, String> _selected = {};
  final Map<String, GarmentModel> _selectedGarments = {};
  String? _collectionId;
  Uint8List? _previewBytes;
  String? _previewName;
  bool _isActive = true;
  bool _saving = false;
  String? _error;
  int _creationStep = 0;

  static const _zones = [
    ('head', 'Tête', Icons.face_rounded, 'headwear'),
    ('jacket', 'Veste', Icons.dry_cleaning_rounded, 'outerwear'),
    ('torso', 'Haut', Icons.checkroom_rounded, 'top'),
    ('legs', 'Bas', Icons.accessibility_new_rounded, 'bottom'),
    ('feet', 'Chaussures', Icons.ice_skating_rounded, 'shoes'),
    ('wrist', 'Accessoire', Icons.watch_rounded, 'accessory'),
  ];

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_selected.isEmpty) {
          setState(() => _error = 'Ajoute au moins une pièce au look.');
          return false;
        }
        return true;
      case 1:
        if (_previewBytes == null) {
          setState(() => _error = 'Ajoute une photo pour le post.');
          return false;
        }
        if (_nameController.text.trim().isEmpty) {
          setState(() => _error = 'Donne un nom à ton post / look.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _goToStep(int step) {
    setState(() {
      _creationStep = step;
      _error = null;
    });
  }

  void _onNextStep() {
    if (!_validateStep(_creationStep)) return;
    if (_creationStep < 2) _goToStep(_creationStep + 1);
  }

  void _onPrevStep() {
    if (_creationStep > 0) _goToStep(_creationStep - 1);
  }

  void _onNameFocusChanged() {
    if (!_nameFocusNode.hasFocus) {
      _nameFocusNode.canRequestFocus = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameFocusNode = FocusNode(skipTraversal: true);
    _nameFocusNode.canRequestFocus = false;
    _nameFocusNode.addListener(_onNameFocusChanged);
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onNameFocusChanged);
    _nameFocusNode.dispose();
    _nameController.dispose();
    _captionController.dispose();
    super.dispose();
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
                color: AppColors.textHint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Photo du post',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _CreatorPostSourceOption(
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
                  child: _CreatorPostSourceOption(
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

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: ImageCaptureDefaults.outfitPhotoMaxWidth,
      imageQuality: ImageCaptureDefaults.outfitPhotoQuality,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _previewBytes = bytes;
      _previewName = picked.name;
    });
  }

  Future<void> _pickGarment(String zoneKey, String categoryKey) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final uid = ref.read(authServiceProvider).uid;
    var garments =
        await ref.read(firestoreServiceProvider).getGarments(uid, category: categoryKey);
    if (_collectionId != null && _collectionId!.isNotEmpty) {
      garments = garments.where((g) => g.collectionId == _collectionId).toList();
    }
    if (!mounted) return;

    final picked = await showGarmentPickerGridSheet(
      context,
      categoryKey: categoryKey,
      garments: garments,
      selectedGarmentId: _selected[zoneKey],
    );
    if (picked != null) {
      setState(() {
        _selected[zoneKey] = picked.id;
        _selectedGarments[zoneKey] = picked;
      });
    }
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  Future<void> _previewFeed() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || _previewBytes == null) {
      setState(() => _error = 'Ajoute une image de preview.');
      return;
    }
    final refs = _selectedGarments.values
        .map((g) => GarmentRef(name: g.name, brand: g.brand, imageUrl: g.imageUrl))
        .toList();
    final post = buildPreviewPost(
      brand: user,
      imageUrl: 'https://placeholder.local/preview.jpg',
      refs: refs,
      caption: _captionController.text.trim(),
    );
    if (!mounted) return;
    await CreatorPostPreviewSheet.show(
      context,
      post,
      ownerGarments: _selectedGarments.values.toList(),
    );
  }

  Future<void> _publish() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    if (_collectionId == null || _collectionId!.isEmpty) {
      setState(() => _error = 'Sélectionne une collection.');
      return;
    }
    if (_previewBytes == null || _previewName == null) {
      setState(() => _error = 'L’image de preview est obligatoire.');
      return;
    }
    final outfitName = _nameController.text.trim();
    if (outfitName.isEmpty) {
      setState(() => _error = 'Donne un nom à ton post / look.');
      return;
    }
    if (_selected.isEmpty) {
      setState(() => _error = 'Ajoute au moins une pièce au look.');
      return;
    }
    final noPhoto = _selectedGarments.values.where((g) => g.imageUrl.isEmpty);
    if (noPhoto.isNotEmpty) {
      setState(() => _error =
          'La pièce « ${noPhoto.first.name} » n’a pas de photo.');
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    final garmentsMap = <String, String>{
      'headwear': '',
      'top': '',
      'outerwear': '',
      'bottom': '',
      'shoes': '',
      'accessory': '',
    };
    for (final e in _selected.entries) {
      final cat = bodyZones[e.key] ?? e.key;
      garmentsMap[cat] = e.value;
    }

    final outfitId = await ref.read(outfitNotifierProvider.notifier).createOutfit(
          userId: user.uid,
          name: outfitName,
          garments: garmentsMap,
        );
    if (outfitId == null) {
      setState(() {
        _saving = false;
        _error = 'Erreur lors de la création du look.';
      });
      return;
    }

    final outfit = (await ref.read(firestoreServiceProvider).getOutfit(user.uid, outfitId));
    if (outfit == null) {
      setState(() {
        _saving = false;
        _error = 'Look introuvable.';
      });
      return;
    }

    final garmentList = _selectedGarments.values.toList();
    final ok = await ref.read(creatorPostNotifierProvider.notifier).createSponsoredPost(
          brand: user,
          outfit: outfit,
          garments: garmentList,
          previewBytes: _previewBytes!,
          previewFileName: _previewName!,
          collectionId: _collectionId!,
          isActive: _isActive,
          caption: _captionController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post publicitaire publié.')),
      );
    } else {
      setState(() => _error = 'Publication impossible.');
    }
  }

  /// Même flux que la création de vêtement : carte puis liste dans une bottom sheet.
  Future<void> _openCollectionPicker(
    BuildContext context,
    List<CollectionModel> collections,
  ) async {
    if (collections.isEmpty) return;
    final chosenId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                child: Row(
                  children: [
                    Icon(Icons.folder_special_rounded,
                        color: AppColors.accent.withValues(alpha: 0.9), size: 26),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Choisir une collection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(12, 4, 12, 16 + bottom),
                  itemCount: collections.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.45)),
                  itemBuilder: (_, i) {
                    final c = collections[i];
                    final selected = c.id == _collectionId;
                    final dateLine =
                        c.startDate.isNotEmpty ? '${c.startDate} → ${c.endDate}' : '';
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(ctx, c.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.accent.withValues(alpha: 0.14)
                                      : AppColors.surfaceVariant.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.collections_bookmark_rounded,
                                  color: selected ? AppColors.accent : AppColors.textHint,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    if (dateLine.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        dateLine,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textHint.withValues(alpha: 0.95),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.accent, size: 24)
                              else
                                Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textHint.withValues(alpha: 0.7)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (chosenId != null && mounted) {
      setState(() => _collectionId = chosenId);
    }
  }

  Widget _buildExistingCollectionPicker(List<CollectionModel> sorted) {
    CollectionModel? selected;
    if (_collectionId != null && _collectionId!.isNotEmpty) {
      for (final c in sorted) {
        if (c.id == _collectionId) {
          selected = c;
          break;
        }
      }
    }

    if (sorted.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Crée d’abord une collection depuis ton catalogue marque.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
              ),
            ),
          ],
        ),
      );
    }

    final subtitle =
        selected != null && selected.startDate.isNotEmpty ? '${selected.startDate} → ${selected.endDate}' : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openCollectionPicker(context, sorted),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.85), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.graphite.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_open_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected?.name ?? 'Choisir une collection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: selected != null ? AppColors.textPrimary : AppColors.textHint,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint.withValues(alpha: 0.8), size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoHero() {
    final hasPhoto = _previewBytes != null && _previewBytes!.isNotEmpty;
    return GestureDetector(
      onTap: _showPhotoSourcePicker,
      child: Container(
        width: double.infinity,
        height: hasPhoto ? 380 : 220,
        margin: const EdgeInsets.fromLTRB(0, 4, 0, 0),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasPhoto ? Colors.transparent : AppColors.accent.withValues(alpha: 0.3),
            width: hasPhoto ? 0 : 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: hasPhoto
              ? [
                  BoxShadow(
                    color: AppColors.graphite.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    _previewBytes!,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.graphite.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 14, color: AppColors.white),
                          SizedBox(width: 4),
                          Text(
                            'Changer',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 28,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ajoute la photo du post',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Obligatoire pour publier',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildGarmentZoneTiles(int selectedCount) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: selectedCount > 0
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$selectedCount/6',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selectedCount > 0 ? AppColors.accent : AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
      ..._zones.asMap().entries.map((entry) {
        final i = entry.key;
        final z = entry.value;
        final (zoneKey, label, icon, catKey) = z;
        final garment = _selectedGarments[zoneKey];
        final hasGarment = garment != null;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: hasGarment ? AppColors.surface : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _pickGarment(zoneKey, catKey),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasGarment
                        ? AppColors.accent.withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    if (hasGarment && garment.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: StorageAwareCachedImage(
                          imageUrl: garment.imageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: (_, __) => _zonePlaceholder(icon, catKey),
                        ),
                      )
                    else
                      _zonePlaceholder(icon, catKey, filled: hasGarment),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasGarment ? garment.name : label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  hasGarment ? FontWeight.w600 : FontWeight.w500,
                              color: hasGarment
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                            ),
                          ),
                          if (hasGarment && garment.brand.isNotEmpty)
                            Text(
                              garment.brand,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
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
                            color: AppColors.error.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 14, color: AppColors.error),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_rounded,
                            size: 14, color: AppColors.accent),
                      ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (50 * i).ms)
            .slideX(begin: 0.04, end: 0, duration: 300.ms, delay: (50 * i).ms);
      }),
    ];
  }

  Widget _zonePlaceholder(IconData icon, String catKey, {bool filled = false}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: filled ? AppColors.surfaceVariant : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: AppColors.textHint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).uid;
    final collectionsAsync = ref.watch(collectionsProvider(uid));
    final selectedCount = _selected.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouveau post pub', style: AppTextStyles.heading3),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CreationStepBreadcrumb(
            currentStep: _creationStep,
            onStep: (i) {
              if (i < _creationStep || _validateStep(_creationStep)) {
                _goToStep(i);
              }
            },
            steps: creatorPostCreationSteps,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (_creationStep == 0) ..._buildGarmentZoneTiles(selectedCount),
                if (_creationStep == 1) ...[
                  _buildPhotoHero(),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      onTap: () {
                        _nameFocusNode.canRequestFocus = true;
                        _nameFocusNode.requestFocus();
                      },
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Nom du post / look',
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
                ],
                if (_creationStep == 2) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: collectionsAsync.when(
                      data: (cols) {
                        final sorted = List<CollectionModel>.from(cols)
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted || sorted.isEmpty) return;
                          final id = _collectionId;
                          if (id != null &&
                              id.isNotEmpty &&
                              !sorted.any((c) => c.id == id)) {
                            setState(() => _collectionId = sorted.first.id);
                          }
                        });
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Collection', style: AppTextStyles.heading3),
                            const SizedBox(height: 8),
                            _buildExistingCollectionPicker(sorted),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) =>
                          Text('Collections : $e', style: const TextStyle(color: AppColors.error)),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Visible dans le feed (actif)'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Légende (optionnel)',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _previewFeed,
                          child: const Text('Aperçu feed'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _publish,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Publier'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_error != null && _creationStep != 2) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  if (_creationStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onPrevStep,
                        child: const Text('Précédent'),
                      ),
                    ),
                  if (_creationStep > 0) const SizedBox(width: 12),
                  if (_creationStep < 2)
                    Expanded(
                      child: FilledButton(
                        onPressed: _onNextStep,
                        child: const Text('Suivant'),
                      ),
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

class _CreatorPostSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CreatorPostSourceOption({
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
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: AppColors.accent),
              ),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
