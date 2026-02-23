import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  XFile? _imageFile;
  String? _error;
  bool _loading = false;
  bool _removeBackground = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.garment?.name ?? '');
    _brandController = TextEditingController(text: widget.garment?.brand ?? '');
    _selectedColors = widget.garment?.colors ?? [];
    _selectedCategory = widget.garment?.category ?? 'top';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
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
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choisir depuis la galerie'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, maxWidth: 600, imageQuality: 78);
    if (picked != null) {
      setState(() => _imageFile = picked);
    }
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
    Uint8List? imageBytes;
    String? imageName;
    if (_imageFile != null) {
      imageBytes = await _imageFile!.readAsBytes();
      imageName = _imageFile!.name;
    }

    try {
      // Vérifier que le backend est accessible avant d'essayer l'upload
      if (imageBytes != null && imageName != null) {
        try {
          // Test de connexion rapide (l'endpoint /health est à la racine, pas sous /api/v1)
          final testResponse = await http.get(
            Uri.parse('http://localhost:8000/health'),
          ).timeout(const Duration(seconds: 3));
          if (testResponse.statusCode != 200) {
            throw Exception('Backend non disponible');
          }
        } catch (e) {
          setState(() {
            _loading = false;
            _error = 'Le backend n\'est pas démarré. Lance-le avec: cd backend && .\\start.ps1';
          });
          return;
        }
      }

      final success = widget.garment == null
          ? await ref.read(garmentNotifierProvider.notifier).addGarment(
                userId: uid,
                name: name,
                brand: _brandController.text.trim(),
                colors: _selectedColors,
                category: _selectedCategory,
                imageBytes: imageBytes,
                imageName: imageName,
                removeBackground: _removeBackground,
              )
          : await ref.read(garmentNotifierProvider.notifier).updateGarment(
                uid: uid,
                garmentId: widget.garment!.id,
                name: name,
                brand: _brandController.text.trim(),
                colors: _selectedColors,
                category: _selectedCategory,
                imageBytes: imageBytes,
                imageName: imageName,
                removeBackground: _removeBackground,
              );

      if (mounted) {
        setState(() => _loading = false);
        if (success) {
          // Attendre un peu pour que Firestore se synchronise avant de fermer
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
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
          // Récupérer le message d'erreur depuis le state du provider
          final errorState = ref.read(garmentNotifierProvider);
          String errorMessage = 'Erreur lors de l\'enregistrement.';
          if (errorState.hasError) {
            final error = errorState.error.toString();
            if (error.contains('Timeout')) {
              errorMessage = 'Le traitement de l\'image prend trop de temps (rembg). Vérifie que le backend est démarré et patiente.';
            } else if (error.contains('connexion') || error.contains('serveur') || error.contains('localhost')) {
              errorMessage = 'Impossible de contacter le backend. Lance-le avec: cd backend && .\\start.ps1';
            } else if (error.contains('FileNotFoundError') || error.contains('serviceAccountKey')) {
              errorMessage = 'Configuration Firebase manquante. Vérifie le fichier serviceAccountKey.json dans backend/';
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
          if (errorStr.contains('localhost') || errorStr.contains('connection')) {
            _error = 'Le backend n\'est pas démarré. Lance-le avec: cd backend && .\\start.ps1';
          } else {
            _error = errorStr.replaceAll('Exception: ', '').replaceAll('Error: ', '');
          }
        });
      }
    }
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
            // Indicateur de glissement
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Titre
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
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.divider, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _imageFile != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  PlatformImage(file: _imageFile!, fit: BoxFit.cover),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _imageFile = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : widget.garment?.imageUrl.isNotEmpty == true
                                ? CachedNetworkImage(
                                    imageUrl: widget.garment!.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.surfaceVariant,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.textHint),
                                      SizedBox(height: 8),
                                      Text('Ajouter une photo', style: AppTextStyles.caption),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: _removeBackground,
                      onChanged: (value) {
                        setState(() => _removeBackground = value);
                      },
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
                            color: selected ? Colors.white : AppColors.textSecondary,
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                widget.garment == null ? 'Enregistrer' : 'Modifier',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
