import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/categories.dart';
import '../models/garment_model.dart';
import '../providers/auth_provider.dart';
import '../providers/garment_provider.dart';
import '../widgets/platform_image.dart';
import '../widgets/brand_selector.dart';
import '../widgets/multi_color_selector.dart';
import '../widgets/premium_upgrade_dialog.dart';
import '../widgets/storage_aware_cached_image.dart';

const int _kMaxGarmentImages = 8;

/// Une photo locale choisie ou une URL déjà en ligne (édition).
class _GarmentImageSlot {
  _GarmentImageSlot.network(this.networkUrl) : file = null;
  _GarmentImageSlot.local(this.file) : networkUrl = null;

  final String? networkUrl;
  final XFile? file;
}

class AddGarmentSheet extends ConsumerStatefulWidget {
  final GarmentModel? garment;

  const AddGarmentSheet({super.key, this.garment});

  @override
  ConsumerState<AddGarmentSheet> createState() => _AddGarmentSheetState();
}

class _AddGarmentSheetState extends ConsumerState<AddGarmentSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late List<String> _selectedColors;
  late String _selectedCategory;

  final List<_GarmentImageSlot> _slots = [];
  final Set<String> _analyzedPaths = {};
  bool _primaryAiApplied = false;
  /// Une seule analyse IA par ouverture de la feuille (première photo locale traitée).
  bool _garmentAiAnalysisConsumed = false;

  late final PageController _previewController;
  int _previewPage = 0;

  String? _error;
  bool _loading = false;
  bool _removeBackground = false;
  bool _useAiAnalysis = true;
  bool _aiAnalyzing = false;
  Map<String, dynamic>? _aiAttributes;

  @override
  void initState() {
    super.initState();
    _previewController = PageController();
    _nameController = TextEditingController(text: widget.garment?.name ?? '');
    _brandController = TextEditingController(text: widget.garment?.brand ?? '');
    _selectedColors = List<String>.from(widget.garment?.colors ?? []);
    _selectedCategory = widget.garment?.category ?? 'top';

    if (widget.garment != null) {
      final urls = widget.garment!.imageUrls.isNotEmpty
          ? widget.garment!.imageUrls
          : (widget.garment!.imageUrl.isNotEmpty ? [widget.garment!.imageUrl] : <String>[]);
      for (final u in urls) {
        if (u.trim().isNotEmpty) {
          _slots.add(_GarmentImageSlot.network(u));
        }
      }
      _primaryAiApplied = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.garment != null) return;
      final premium = ref.read(isPremiumProvider);
      setState(() {
        _useAiAnalysis = premium;
        if (!premium) _removeBackground = false;
      });
    });
  }

  @override
  void dispose() {
    _previewController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  List<String> _mergeColorLists(List<String> a, List<String> b) {
    final seen = a.map((e) => e.toLowerCase()).toSet();
    final out = List<String>.from(a);
    for (final c in b) {
      final k = c.toLowerCase();
      if (!seen.contains(k)) {
        seen.add(k);
        out.add(c);
      }
    }
    return out;
  }

  void _mergeAiIntoForm(Map<String, dynamic> result) {
    const allowedCats = ['top', 'bottom', 'shoes', 'outerwear', 'headwear', 'accessory'];

    setState(() {
      final newColors = (result['colors'] as List?)?.cast<String>() ?? const [];
      _selectedColors = _mergeColorLists(_selectedColors, newColors);

      if (!_primaryAiApplied) {
        final cat = (result['category'] as String?) ?? '';
        if (allowedCats.contains(cat)) {
          _selectedCategory = cat;
        }

        final n = (result['name'] as String?)?.trim() ?? '';
        if (n.isNotEmpty && _nameController.text.trim().isEmpty) {
          _nameController.text = n;
        }

        final b = (result['brand'] as String?)?.trim() ?? '';
        if (b.isNotEmpty && _brandController.text.trim().isEmpty) {
          _brandController.text = b;
        }
        _primaryAiApplied = true;
      }

      final prevTags = (_aiAttributes?['style_tags'] as List?)?.cast<String>() ?? const [];
      final newTags = (result['style_tags'] as List?)?.cast<String>() ?? const [];
      final mergedTags = [...{...prevTags, ...newTags}];

      _aiAttributes = {
        ...result,
        'colors': _selectedColors,
        'style_tags': mergedTags,
      };
    });
  }

  Future<void> _runAiOnPendingLocals() async {
    if (!ref.read(isPremiumProvider)) return;
    if (!_useAiAnalysis) return;
    if (_garmentAiAnalysisConsumed) return;

    _GarmentImageSlot? target;
    for (final slot in _slots) {
      if (slot.file == null) continue;
      final path = slot.file!.path;
      if (_analyzedPaths.contains(path)) continue;
      target = slot;
      break;
    }
    if (target == null) return;

    final path = target.file!.path;

    setState(() => _aiAnalyzing = true);
    final api = ref.read(apiServiceProvider);
    try {
      final bytes = await target.file!.readAsBytes();
      final result = await api.analyzeGarmentImage(bytes, target.file!.name);
      if (!mounted) return;

      _garmentAiAnalysisConsumed = true;

      if (result['is_garment'] == false) {
        setState(() {
          _slots.removeWhere((s) => s.file?.path == path);
        });
        await _showNotGarmentDialog();
        return;
      }

      _analyzedPaths.add(path);
      _mergeAiIntoForm(result);
    } catch (_) {
      _garmentAiAnalysisConsumed = true;
    } finally {
      if (mounted) setState(() => _aiAnalyzing = false);
    }
  }

  void _removeSlotAt(int index) {
    final s = _slots[index];
    if (s.file?.path != null) {
      _analyzedPaths.remove(s.file!.path);
    }
    setState(() {
      _slots.removeAt(index);
      if (_previewPage >= _slots.length && _slots.isNotEmpty) {
        _previewPage = _slots.length - 1;
      } else if (_slots.isEmpty) {
        _previewPage = 0;
      }
    });
  }

  Future<void> _openPickSources() async {
    if (_slots.length >= _kMaxGarmentImages) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Prendre une photo'),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galerie — plusieurs photos'),
                  onTap: () => Navigator.pop(context, 'gallery_multi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final picker = ImagePicker();

    if (choice == 'camera') {
      final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 95);
      if (picked != null && mounted) {
        setState(() => _slots.add(_GarmentImageSlot.local(picked)));
        await _runAiOnPendingLocals();
      }
    } else if (choice == 'gallery_multi') {
      final files = await picker.pickMultiImage(maxWidth: 1200, imageQuality: 95);
      if (files.isNotEmpty && mounted) {
        setState(() {
          for (final f in files) {
            if (_slots.length >= _kMaxGarmentImages) break;
            _slots.add(_GarmentImageSlot.local(f));
          }
        });
        await _runAiOnPendingLocals();
      }
    }
  }

  Future<void> _showNotGarmentDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: AppColors.surface,
        icon: const Icon(Icons.image_not_supported_outlined, color: AppColors.error, size: 36),
        title: const Text(
          'Image non reconnue',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'L’IA n’a pas reconnu de vêtement, chaussure ou accessoire sur cette photo. '
          'Choisis une autre image plus claire montrant la pièce que tu veux ajouter.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Le nom est obligatoire.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });

    final uid = ref.read(authServiceProvider).uid;

    final premium = ref.read(isPremiumProvider);
    final imageBytesList = <Uint8List>[];
    final imageNames = <String>[];
    for (final s in _slots) {
      if (s.file != null) {
        imageBytesList.add(await s.file!.readAsBytes());
        imageNames.add(s.file!.name);
      }
    }

    final needUpload = imageBytesList.isNotEmpty;

    try {
      if (needUpload) {
        try {
          final api = ref.read(apiServiceProvider);
          final healthUrl = api.baseUrl.replaceAll('/api/v1', '/health');
          final testResponse = await http.get(Uri.parse(healthUrl)).timeout(const Duration(seconds: 5));
          if (testResponse.statusCode != 200) {
            throw Exception('Backend non disponible');
          }
        } catch (e) {
          setState(() {
            _loading = false;
            _error = 'Le serveur est inaccessible. Réessaie dans un instant.';
          });
          return;
        }
      }

      final styleTags = (_aiAttributes?['style_tags'] as List?)?.cast<String>() ?? const [];
      final formality = (_aiAttributes?['formality'] as String?) ?? '';
      final season = (_aiAttributes?['season'] as String?) ?? '';
      final pattern = (_aiAttributes?['pattern'] as String?) ?? '';
      final material = (_aiAttributes?['material'] as String?) ?? '';

      final bool success;
      if (widget.garment == null) {
        success = await ref.read(garmentNotifierProvider.notifier).addGarment(
              userId: uid,
              name: name,
              brand: _brandController.text.trim(),
              colors: _selectedColors,
              category: _selectedCategory,
              styleTags: styleTags,
              formality: formality,
              season: season,
              pattern: pattern,
              material: material,
              imageBytesList: imageBytesList,
              imageNames: imageNames,
              removeBackground: premium && _removeBackground,
            );
      } else {
        final keptUrls = _slots.where((s) => s.networkUrl != null).map((s) => s.networkUrl!).toList();
        success = await ref.read(garmentNotifierProvider.notifier).updateGarment(
              uid: uid,
              garmentId: widget.garment!.id,
              name: name,
              brand: _brandController.text.trim(),
              colors: _selectedColors,
              category: _selectedCategory,
              keptImageUrls: keptUrls,
              newImageBytesList: imageBytesList,
              newImageNames: imageNames,
              removeBackground: premium && _removeBackground,
            );
      }

      if (mounted) {
        setState(() => _loading = false);
        if (success) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(widget.garment == null ? 'Vêtement ajouté !' : 'Vêtement modifié !'),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          final errorState = ref.read(garmentNotifierProvider);
          String errorMessage = 'Erreur lors de l\'enregistrement.';
          if (errorState.hasError) {
            final error = errorState.error.toString();
            if (error.contains('Timeout')) {
              errorMessage =
                  'Le traitement d\'une image prend trop de temps. Vérifie que le backend est démarré et patiente.';
            } else if (error.contains('connexion') ||
                error.contains('serveur') ||
                error.contains('localhost')) {
              errorMessage = 'Impossible de contacter le serveur. Réessaie dans un instant.';
            } else if (error.contains('FileNotFoundError') || error.contains('serviceAccountKey')) {
              errorMessage =
                  'Configuration Firebase manquante. Vérifie le fichier serviceAccountKey.json dans backend/';
            } else {
              errorMessage = error
                  .replaceAll('Exception: ', '')
                  .replaceAll('Error: ', '')
                  .replaceAll('FileNotFoundError: ', '')
                  .replaceAll('[Errno 2] ', '');
            }
          }
          setState(() => _error = errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          final errorStr = e.toString();
          if (errorStr.contains('localhost') ||
              errorStr.contains('connection') ||
              errorStr.contains('connexion')) {
            _error = 'Le serveur est inaccessible. Réessaie dans un instant.';
          } else {
            _error = errorStr.replaceAll('Exception: ', '').replaceAll('Error: ', '');
          }
        });
      }
    }
  }

  Widget _buildPhotoPreview() {
    if (_slots.isEmpty) {
      return GestureDetector(
        onTap: _openPickSources,
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider, width: 1.5),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.textHint),
              SizedBox(height: 8),
              Text('Ajouter une ou plusieurs photos', style: AppTextStyles.caption),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _previewController,
            itemCount: _slots.length,
            onPageChanged: (i) => setState(() {
              _previewPage = i;
            }),
            itemBuilder: (context, i) {
              final s = _slots[i];
              if (s.networkUrl != null) {
                return StorageAwareCachedImage(
                  imageUrl: s.networkUrl!,
                  fit: BoxFit.cover,
                  loadingWidget: Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, __) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.textHint),
                  ),
                );
              }
              return PlatformImage(file: s.file!, fit: BoxFit.cover);
            },
          ),
          if (_aiAnalyzing)
            Container(
              color: AppColors.graphite.withOpacity(0.55),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.white),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Analyse des images par l’IA…',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (!_aiAnalyzing && _slots.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slots.length, (i) {
                  final sel = i == _previewPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: sel ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.white : AppColors.white.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.graphite.withOpacity(0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          if (!_aiAnalyzing)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeSlotAt(_previewPage),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: AppColors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiSwitchSection(BuildContext context, bool isPremium) {
    final tiles = Column(
      children: [
        SwitchListTile.adaptive(
          value: _removeBackground,
          onChanged: !isPremium || _aiAnalyzing
              ? null
              : (value) => setState(() => _removeBackground = value),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Supprimer l’arrière-plan',
            style: AppTextStyles.bodySecondary,
          ),
          subtitle: const Text(
            'Utilise l’IA pour isoler le vêtement. Décoche si tu veux garder le fond.',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
        SwitchListTile.adaptive(
          value: _useAiAnalysis,
          onChanged: !isPremium || _aiAnalyzing
              ? null
              : (value) => setState(() => _useAiAnalysis = value),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Pré-remplir avec l’IA',
            style: AppTextStyles.bodySecondary,
          ),
          subtitle: const Text(
            'Une seule analyse par ajout : la première photo (couleurs, catégorie, etc.).',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
      ],
    );

    if (isPremium) return tiles;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(opacity: 0.52, child: AbsorbPointer(child: tiles)),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showPremiumUpgradeDialog(context),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    widget.garment == null ? 'Nouveau vêtement' : 'Modifier le vêtement',
                    style: AppTextStyles.heading2.copyWith(fontSize: 22),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoPreview(),
                    const SizedBox(height: 10),
                    if (_slots.length < _kMaxGarmentImages)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _aiAnalyzing ? null : _openPickSources,
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                          label: Text(
                            _slots.isEmpty
                                ? 'Ajouter des photos'
                                : 'Ajouter d’autres photos (${_slots.length}/$_kMaxGarmentImages)',
                          ),
                          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                        ),
                      ),
                    const SizedBox(height: 4),
                    _buildAiSwitchSection(context, ref.watch(isPremiumProvider)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Nom / description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    BrandSelector(
                      controller: _brandController,
                      initialValue: widget.garment?.brand,
                    ),
                    const SizedBox(height: 16),
                    const Text('Couleurs', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    MultiColorSelector(
                      key: ValueKey('colors_${_selectedColors.join("_")}'),
                      initialColors: _selectedColors,
                      onColorsChanged: (colors) {
                        setState(() => _selectedColors = colors);
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('Catégorie', style: AppTextStyles.heading3),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final selected = _selectedCategory == cat.key;
                        return ChoiceChip(
                          label: Text(cat.label),
                          avatar: Icon(cat.icon, size: 18),
                          selected: selected,
                          selectedColor: AppColors.accent,
                          labelStyle: TextStyle(
                            color: selected ? AppColors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          onSelected: (_) => setState(() => _selectedCategory = cat.key),
                        );
                      }).toList(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                              )
                            : Text(
                                widget.garment == null ? 'Enregistrer' : 'Modifier',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
