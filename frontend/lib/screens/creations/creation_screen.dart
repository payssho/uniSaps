import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/categories.dart';
import '../../models/garment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/garment_provider.dart';

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
  String? _message;
  bool _isError = false;
  String? _referencePhotoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickReferencePhoto() async {
    final uid = ref.read(authServiceProvider).uid;
    if (uid.isEmpty) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 78,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final storage = ref.read(storageServiceProvider);
    try {
      final url =
          await storage.uploadOutfitPhotoBytes(bytes, uid, picked.name);
      if (mounted) {
        setState(() {
          _referencePhotoUrl = url;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'upload de la photo de reference"),
        ),
      );
    }
  }

  Future<void> _pickGarment(String zoneKey, String categoryKey) async {
    final uid = ref.read(authServiceProvider).uid;
    final garments = await ref.read(firestoreServiceProvider).getGarments(uid, category: categoryKey);
    if (!mounted) return;

    final picked = await showModalBottomSheet<GarmentModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(categoryLabel(categoryKey), style: AppTextStyles.heading3),
            ),
            const Divider(height: 1),
            Expanded(
              child: garments.isEmpty
                  ? const Center(child: Text('Aucun vetement dans cette categorie', style: AppTextStyles.bodySecondary))
                  : GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: garments.length,
                      itemBuilder: (_, i) {
                        final g = garments[i];
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, g),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selected[zoneKey] == g.id
                                    ? AppColors.accent
                                    : AppColors.divider,
                                width: _selected[zoneKey] == g.id ? 2 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Expanded(
                                  child: g.imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: g.imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        )
                                      : Container(
                                          color: AppColors.surfaceVariant,
                                          child: Icon(categoryIcon(categoryKey), color: AppColors.textHint),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    g.name,
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _message = 'Donne un nom a ton outfit.';
        _isError = true;
      });
      return;
    }
    if (_selected.isEmpty) {
      setState(() {
        _message = 'Selectionne au moins un vetement.';
        _isError = true;
      });
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });

    final uid = ref.read(authServiceProvider).uid;
    final garments = <String, String>{
      'headwear': '', 'top': '', 'outerwear': '',
      'bottom': '', 'shoes': '', 'accessory': '',
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
        );

    if (mounted) {
      setState(() => _saving = false);
      if (id != null) {
        setState(() {
          _message = 'Outfit cree !';
          _isError = false;
          _nameController.clear();
          _selected.clear();
          _selectedGarments.clear();
          _referencePhotoUrl = null;
        });
      } else {
        setState(() {
          _message = 'Erreur lors de la creation.';
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zones = [
      ('head', 'Tete', Icons.face, 'headwear'),
      ('jacket', 'Veste', Icons.dry_cleaning, 'outerwear'),
      ('torso', 'Haut', Icons.checkroom, 'top'),
      ('legs', 'Bas', Icons.accessibility_new, 'bottom'),
      ('feet', 'Chaussures', Icons.ice_skating, 'shoes'),
      ('wrist', 'Accessoire', Icons.watch, 'accessory'),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text('Creer un Outfit', style: AppTextStyles.heading2),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Nom de l\'outfit'),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_referencePhotoUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: _referencePhotoUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 200,
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 200,
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textHint,
                              size: 40,
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 16, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: AppColors.textHint,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Photo de reference (optionnelle)',
                                style: AppTextStyles.bodySecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickReferencePhoto,
                          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                          label: Text(
                            _referencePhotoUrl == null
                                ? 'Ajouter une photo'
                                : 'Changer la photo',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              ...zones.map((z) {
                final (zoneKey, label, icon, catKey) = z;
                final garment = _selectedGarments[zoneKey];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: garment != null && garment.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: garment.imageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: AppColors.textHint),
                          ),
                    title: Text(garment?.name ?? label),
                    subtitle: garment != null ? Text(garment.brand, style: AppTextStyles.caption) : null,
                    trailing: garment != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() {
                              _selected.remove(zoneKey);
                              _selectedGarments.remove(zoneKey);
                            }),
                          )
                        : const Icon(Icons.add, color: AppColors.accent),
                    onTap: () => _pickGarment(zoneKey, catKey),
                  ),
                );
              }),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (_isError ? AppColors.error : AppColors.success).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isError ? AppColors.error : AppColors.success,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isError ? Icons.error_outline : Icons.check_circle_outline,
                        color: _isError ? AppColors.error : AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _isError ? AppColors.error : AppColors.success,
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
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sauvegarder'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
