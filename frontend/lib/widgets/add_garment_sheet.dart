import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/categories.dart';
import '../models/garment_model.dart';
import '../models/user_model.dart';
import '../models/collection_model.dart';
import '../providers/auth_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/garment_provider.dart';
import '../widgets/platform_image.dart';
import '../widgets/brand_selector.dart';
import '../widgets/multi_color_selector.dart';
import '../widgets/premium_upgrade_dialog.dart';
import '../widgets/storage_aware_cached_image.dart';
import '../widgets/garment_category_glyph.dart';

const int _kMaxGarmentImages = 8;

/// Marque affichée / enregistrée pour le catalogue créateur : pseudo avec @.
String creatorCatalogBrandLabel(UserModel user) {
  final raw = user.username.trim();
  if (raw.isEmpty) {
    final d = user.displayName.trim();
    if (d.isEmpty) return '';
    return d.startsWith('@') ? d : '@$d';
  }
  return raw.startsWith('@') ? raw : '@$raw';
}

/// Une photo locale choisie ou une URL déjà en ligne (édition).
class _GarmentImageSlot {
  _GarmentImageSlot.network(this.networkUrl) : file = null;
  _GarmentImageSlot.local(this.file) : networkUrl = null;

  final String? networkUrl;
  final XFile? file;
}

class AddGarmentSheet extends ConsumerStatefulWidget {
  final GarmentModel? garment;
  final bool requireCollection;
  final String? initialCollectionId;
  /// Flux catalogue marque : pas de suppression de fond IA, marque = @ du compte.
  final bool creatorCatalogMode;

  const AddGarmentSheet({
    super.key,
    this.garment,
    this.requireCollection = false,
    this.initialCollectionId,
    this.creatorCatalogMode = false,
  });

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
  String? _selectedCollectionId;
  bool _creatingCollection = false;
  final _newCollectionNameController = TextEditingController();
  final _collectionStartController = TextEditingController();
  final _collectionEndController = TextEditingController();

  /// Catalogue créateur : même logique que [CreatorPostCreateSheet] pour éviter que le focus
  /// revienne sur le nom après une bottom sheet (photos, collection…).
  FocusNode? _creatorCatalogNameFocusNode;

  void _onCreatorCatalogNameFocusChanged() {
    final n = _creatorCatalogNameFocusNode;
    if (n != null && !n.hasFocus) {
      n.canRequestFocus = false;
    }
  }

  void _unfocusAfterCreatorCatalogSheet() {
    if (!widget.creatorCatalogMode || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.creatorCatalogMode) {
      _useAiAnalysis = false;
    }
    _previewController = PageController();
    _nameController = TextEditingController(text: widget.garment?.name ?? '');
    _brandController = TextEditingController(text: widget.garment?.brand ?? '');
    _selectedColors = List<String>.from(widget.garment?.colors ?? []);
    _selectedCategory = widget.garment?.category ?? 'top';
    _selectedCollectionId = widget.garment?.collectionId.isNotEmpty == true
        ? widget.garment!.collectionId
        : widget.initialCollectionId;

    if (widget.creatorCatalogMode) {
      _creatorCatalogNameFocusNode = FocusNode(skipTraversal: true);
      _creatorCatalogNameFocusNode!.canRequestFocus = false;
      _creatorCatalogNameFocusNode!.addListener(_onCreatorCatalogNameFocusChanged);
    }

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

    // Ne pas lier _useAiAnalysis au tier ici : tant que le doc Firestore n'est pas
    // chargé, isPremium est faux → l'IA était ignorée en ~1 s sans message.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;
      if (widget.creatorCatalogMode) {
        final label = creatorCatalogBrandLabel(user);
        if (label.isNotEmpty) {
          setState(() => _brandController.text = label);
        }
        setState(() => _removeBackground = false);
      } else if (widget.garment == null && !user.isPremium) {
        setState(() => _removeBackground = false);
      }
    });
  }

  @override
  void dispose() {
    _previewController.dispose();
    if (_creatorCatalogNameFocusNode != null) {
      _creatorCatalogNameFocusNode!.removeListener(_onCreatorCatalogNameFocusChanged);
      _creatorCatalogNameFocusNode!.dispose();
    }
    _nameController.dispose();
    _brandController.dispose();
    _newCollectionNameController.dispose();
    _collectionStartController.dispose();
    _collectionEndController.dispose();
    super.dispose();
  }

  /// Réponses « vides » du backend (Gemini indisponible, quota, parse raté) - déclenche un second essai.
  bool _isVacuousGarmentAnalysis(Map<String, dynamic> r) {
    if (r['is_garment'] == false) return false;
    const allowedCats = {'top', 'bottom', 'shoes', 'outerwear', 'headwear', 'accessory'};
    final cat = ((r['category'] as String?) ?? '').trim().toLowerCase();
    final name = ((r['name'] as String?) ?? '').trim();
    final colors = (r['colors'] as List?) ?? const [];
    return name.isEmpty && !allowedCats.contains(cat) && colors.isEmpty;
  }

  /// Attend le document Firestore pour que [isPremiumProvider] reflète le tier réel (évite sortie IA en ~0 s).
  Future<void> _waitForFirestoreUser() async {
    final expectedUid = ref.read(authServiceProvider).uid;
    if (expectedUid.isEmpty) return;
    const step = Duration(milliseconds: 80);
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (mounted && DateTime.now().isBefore(deadline)) {
      final u = ref.read(currentUserProvider).valueOrNull;
      if (u != null && u.uid == expectedUid) return;
      await Future.delayed(step);
    }
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

        if (!widget.creatorCatalogMode) {
          final b = (result['brand'] as String?)?.trim() ?? '';
          if (b.isNotEmpty && _brandController.text.trim().isEmpty) {
            _brandController.text = b;
          }
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
    if (!_useAiAnalysis) return;
    if (_garmentAiAnalysisConsumed) return;

    await _waitForFirestoreUser();
    if (!mounted) return;
    if (!ref.read(isPremiumProvider)) return;

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
      Map<String, dynamic> result;
      try {
        result = await api.analyzeGarmentImage(bytes, target.file!.name);
        if (_isVacuousGarmentAnalysis(result) && mounted) {
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          result = await api.analyzeGarmentImage(bytes, target.file!.name);
        }
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        result = await api.analyzeGarmentImage(bytes, target.file!.name);
        if (_isVacuousGarmentAnalysis(result) && mounted) {
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          result = await api.analyzeGarmentImage(bytes, target.file!.name);
        }
      }
      if (!mounted) return;

      if (result['is_garment'] == false) {
        _garmentAiAnalysisConsumed = true;
        setState(() {
          _slots.removeWhere((s) => s.file?.path == path);
        });
        await _showNotGarmentDialog();
        return;
      }

      if (_isVacuousGarmentAnalysis(result) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'L’IA n’a pas pu décrire cette photo (service saturé ou image peu lisible). '
              'Tu peux remplir les champs manuellement ou réessayer avec une autre photo.',
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 5),
          ),
        );
      }

      _garmentAiAnalysisConsumed = true;
      _analyzedPaths.add(path);
      _mergeAiIntoForm(result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Analyse IA indisponible. Vérifie ta connexion et réessaie dans un instant.',
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 4),
          ),
        );
      }
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

    if (widget.creatorCatalogMode) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    try {
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
                  title: const Text('Galerie - plusieurs photos'),
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
        final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 82);
        if (picked != null && mounted) {
          setState(() => _slots.add(_GarmentImageSlot.local(picked)));
          await _runAiOnPendingLocals();
        }
      } else if (choice == 'gallery_multi') {
        final files = await picker.pickMultiImage(maxWidth: 1200, imageQuality: 82);
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
    } finally {
      _unfocusAfterCreatorCatalogSheet();
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
    if (widget.creatorCatalogMode) {
      final u = ref.read(currentUserProvider).valueOrNull;
      if (u == null || creatorCatalogBrandLabel(u).isEmpty) {
        setState(() => _error =
            'Ton pseudo (@identifiant) est introuvable. Complète ton profil créateur.');
        return;
      }
    }
    if (widget.requireCollection && widget.garment == null) {
      if (_creatingCollection) {
        final cName = _newCollectionNameController.text.trim();
        if (cName.isEmpty) {
          setState(() => _error = 'Le nom de la collection est obligatoire.');
          return;
        }
      } else if (_selectedCollectionId == null || _selectedCollectionId!.isEmpty) {
        setState(() => _error = 'Sélectionne une collection.');
        return;
      }
    }
    setState(() {
      _error = null;
      _loading = true;
    });

    final uid = ref.read(authServiceProvider).uid;
    var collectionId = _selectedCollectionId ?? '';
    if (widget.requireCollection && widget.garment == null && _creatingCollection) {
      final now = DateTime.now().toIso8601String().substring(0, 10);
      final start = _collectionStartController.text.trim().isNotEmpty
          ? _collectionStartController.text.trim()
          : now;
      final end = _collectionEndController.text.trim().isNotEmpty
          ? _collectionEndController.text.trim()
          : now;
      final newId = await ref.read(collectionNotifierProvider.notifier).createCollection(
            userId: uid,
            name: _newCollectionNameController.text.trim(),
            startDate: start,
            endDate: end,
          );
      if (newId == null) {
        setState(() {
          _loading = false;
          _error = 'Impossible de créer la collection.';
        });
        return;
      }
      collectionId = newId;
    }

    final premium = ref.read(isPremiumProvider);
    final userForBrand = ref.read(currentUserProvider).valueOrNull;
    final brand = widget.creatorCatalogMode && userForBrand != null
        ? creatorCatalogBrandLabel(userForBrand)
        : _brandController.text.trim();
    final stripBackground = premium && _removeBackground && !widget.creatorCatalogMode;
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
      // Ping backend uniquement si l’upload passe par l’API (ex. suppression de fond).
      // Sinon upload Firebase direct → pas de dépendance au backend (catalogue créateur, etc.).
      if (needUpload && stripBackground) {
        try {
          final api = ref.read(apiServiceProvider);
          final healthUrl = api.baseUrl.replaceAll('/api/v1', '/health');
          final testResponse =
              await http.get(Uri.parse(healthUrl)).timeout(const Duration(seconds: 15));
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
              brand: brand,
              colors: _selectedColors,
              category: _selectedCategory,
              styleTags: styleTags,
              formality: formality,
              season: season,
              pattern: pattern,
              material: material,
              imageBytesList: imageBytesList,
              imageNames: imageNames,
              removeBackground: stripBackground,
              collectionId: collectionId,
            );
      } else {
        final keptUrls = _slots.where((s) => s.networkUrl != null).map((s) => s.networkUrl!).toList();
        success = await ref.read(garmentNotifierProvider.notifier).updateGarment(
              uid: uid,
              garmentId: widget.garment!.id,
              name: name,
              brand: brand,
              colors: _selectedColors,
              category: _selectedCategory,
              keptImageUrls: keptUrls,
              newImageBytesList: imageBytesList,
              newImageNames: imageNames,
              removeBackground: stripBackground,
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
            } else if (error.contains('compte de service Firebase') ||
                error.contains('Storage Admin') ||
                error.contains('Storage Object Creator') ||
                (error.contains('Firebase Storage') &&
                    (error.contains('droits') ||
                        error.contains('écriture')))) {
              // Le backend renvoie souvent du 503 avec « 403 » dans le détail GCS : ce n’est pas une session expirée.
              errorMessage =
                  'Le serveur n’a pas les droits pour enregistrer l’image sur Firebase Storage. '
                  'Dans Google Cloud Console → IAM, attribue au compte de service du backend '
                  '(clef utilisée par l’API, ex. serviceAccountKey.json) le rôle '
                  '« Storage Object Creator » ou « Storage Admin », puis réessaie.';
            } else if (error.contains('Token Firebase invalide') ||
                error.contains('401')) {
              errorMessage =
                  'Session expirée ou jeton invalide. Déconnecte-toi, reconnecte-toi, puis réessaie.';
            } else if (error.contains('403') || error.contains('Forbidden')) {
              errorMessage =
                  'Accès refusé par le serveur. Si tu viens de te connecter, réessaie dans quelques secondes ; sinon préviens le support.';
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

  /// Sélecteur de collection : bottom sheet (évite les bugs du DropdownButtonFormField).
  Future<void> _openCollectionPicker(
    BuildContext context,
    List<CollectionModel> collections,
  ) async {
    if (collections.isEmpty) return;
    if (widget.creatorCatalogMode) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
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
                    Icon(Icons.folder_special_rounded, color: AppColors.accent.withValues(alpha: 0.9), size: 26),
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
                    final selected = c.id == _selectedCollectionId;
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
                                const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 24)
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
      setState(() => _selectedCollectionId = chosenId);
    }
    _unfocusAfterCreatorCatalogSheet();
  }

  Widget _buildExistingCollectionPicker(List<CollectionModel> sorted) {
    CollectionModel? selected;
    if (_selectedCollectionId != null && _selectedCollectionId!.isNotEmpty) {
      for (final c in sorted) {
        if (c.id == _selectedCollectionId) {
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

  Widget _buildCollectionSection(String uid) {
    final collectionsAsync = ref.watch(collectionsProvider(uid));
    return collectionsAsync.when(
      data: (collections) {
        final sorted = List<CollectionModel>.from(collections)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _creatingCollection || sorted.isEmpty) return;
          final id = _selectedCollectionId;
          if (id != null && id.isNotEmpty && !sorted.any((c) => c.id == id)) {
            setState(() => _selectedCollectionId = sorted.first.id);
          }
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collection',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Existante'),
                  icon: Icon(Icons.folder_open_outlined, size: 18),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Nouvelle'),
                  icon: Icon(Icons.create_new_folder_outlined, size: 18),
                ),
              ],
              selected: {_creatingCollection},
              style: SegmentedButton.styleFrom(
                selectedForegroundColor: AppColors.white,
                selectedBackgroundColor: AppColors.accent,
                foregroundColor: AppColors.textSecondary,
                backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.35),
                side: BorderSide(color: AppColors.divider.withValues(alpha: 0.65)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                setState(() => _creatingCollection = s.first);
              },
            ),
            const SizedBox(height: 14),
            if (!_creatingCollection)
              _buildExistingCollectionPicker(sorted)
            else ...[
              TextField(
                controller: _newCollectionNameController,
                scrollPadding: EdgeInsets.zero,
                decoration: const InputDecoration(
                  hintText: 'Nom de la collection',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _collectionStartController,
                      scrollPadding: EdgeInsets.zero,
                      decoration: const InputDecoration(
                        labelText: 'Début (AAAA-MM-JJ)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _collectionEndController,
                      scrollPadding: EdgeInsets.zero,
                      decoration: const InputDecoration(
                        labelText: 'Fin (AAAA-MM-JJ)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Collections : $e', style: const TextStyle(color: AppColors.error)),
    );
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
    if (widget.creatorCatalogMode) {
      return const SizedBox.shrink();
    }
    final tiles = Column(
      children: [
        if (!widget.creatorCatalogMode)
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
              onTap: () => showPremiumUpgradeDialog(context, ref: ref),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (prev, next) {
      if (!mounted) return;
      final user = next.valueOrNull;
      if (widget.creatorCatalogMode) {
        if (user != null) {
          final label = creatorCatalogBrandLabel(user);
          if (label.isNotEmpty && mounted) {
            setState(() => _brandController.text = label);
          }
        }
        if (_removeBackground && mounted) {
          setState(() => _removeBackground = false);
        }
        return;
      }
      if (widget.garment != null) return;
      if (user != null && !user.isPremium && _removeBackground) {
        setState(() => _removeBackground = false);
      }
    });

    final bottomPad =
        24.0 + MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.garment == null ? 'Nouveau vêtement' : 'Modifier le vêtement',
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      _buildPhotoPreview(),
                      if (_slots.isNotEmpty && _slots.length < _kMaxGarmentImages) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _aiAnalyzing ? null : _openPickSources,
                            icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                            label: Text(
                              'Ajouter d’autres photos (${_slots.length}/$_kMaxGarmentImages)',
                            ),
                            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      _buildAiSwitchSection(context, ref.watch(isPremiumProvider)),
                      const SizedBox(height: 24),
                      const Text('Nom', style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        focusNode: widget.creatorCatalogMode ? _creatorCatalogNameFocusNode : null,
                        onTap: widget.creatorCatalogMode
                            ? () {
                                _creatorCatalogNameFocusNode?.canRequestFocus = true;
                                _creatorCatalogNameFocusNode?.requestFocus();
                              }
                            : null,
                        scrollPadding: EdgeInsets.zero,
                        decoration: const InputDecoration(
                          hintText: 'Nom / description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!widget.creatorCatalogMode) ...[
                        BrandSelector(
                          controller: _brandController,
                          initialValue: widget.garment?.brand,
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text('Couleurs', style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      MultiColorSelector(
                        key: ValueKey('colors_${_selectedColors.join("_")}'),
                        initialColors: _selectedColors,
                        onColorsChanged: (colors) {
                          setState(() => _selectedColors = colors);
                        },
                      ),
                      if (widget.requireCollection) ...[
                        const SizedBox(height: 24),
                        _buildCollectionSection(ref.watch(authServiceProvider).uid),
                      ],
                      const SizedBox(height: 24),
                      const Text('Catégorie', style: AppTextStyles.heading3),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 10.0;
                          final tileW = (constraints.maxWidth - spacing) / 2;
                          return Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: spacing,
                            runSpacing: spacing,
                            children: categories.map((cat) {
                              final selected = _selectedCategory == cat.key;
                              final fg =
                                  selected ? AppColors.white : AppColors.textSecondary;
                              final bg = selected
                                  ? AppColors.accent
                                  : AppColors.surfaceVariant.withValues(alpha: 0.4);
                              final border = selected
                                  ? AppColors.accent
                                  : AppColors.divider.withValues(alpha: 0.65);
                              return SizedBox(
                                width: tileW,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _selectedCategory = cat.key),
                                    borderRadius: BorderRadius.circular(14),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      curve: Curves.easeOutCubic,
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: border,
                                          width: selected ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: Center(
                                              child: GarmentCategoryGlyph(
                                                categoryKey: cat.key,
                                                color: fg,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            cat.label,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              height: 1.2,
                                              letterSpacing: -0.2,
                                              color: fg,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

/// Même présentation que la création de look : route plein écran, transition depuis le bas,
/// fermeture par la croix (pas de sheet ni swipe pour fermer).
Future<void> pushAddGarmentRoute(
  BuildContext context, {
  GarmentModel? garment,
  bool requireCollection = false,
  String? initialCollectionId,
  bool creatorCatalogMode = false,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => AddGarmentSheet(
        garment: garment,
        requireCollection: requireCollection,
        initialCollectionId: initialCollectionId,
        creatorCatalogMode: creatorCatalogMode,
      ),
      transitionsBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}
