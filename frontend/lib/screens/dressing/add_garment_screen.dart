import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/categories.dart';
import '../../l10n/domain_l10n.dart';
import '../../l10n/l10n_context.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garment_provider.dart';
import '../../widgets/garment_category_glyph.dart';
import '../../widgets/platform_image.dart';

class AddGarmentScreen extends ConsumerStatefulWidget {
  const AddGarmentScreen({super.key});

  @override
  ConsumerState<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends ConsumerState<AddGarmentScreen> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();
  XFile? _imageFile;
  String _selectedCategory = 'top';
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final l10n = context.l10n;
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final sheetL10n = sheetCtx.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: Text(sheetL10n.pickerCamera),
                  onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(sheetL10n.pickerGallery),
                  onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null) return;
    final picked =
        await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 95);
    if (picked != null) {
      setState(() => _imageFile = picked);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.garmentNameRequired);
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
    final success = await ref.read(garmentNotifierProvider.notifier).addGarment(
          userId: uid,
          name: name,
          brand: _brandController.text.trim(),
          colors: [
            if (_colorController.text.trim().isNotEmpty)
              _colorController.text.trim(),
          ],
          category: _selectedCategory,
          imageBytesList: imageBytes != null && imageName != null
              ? [imageBytes]
              : const [],
          imageNames:
              imageBytes != null && imageName != null ? [imageName] : const [],
        );

    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _error = l10n.garmentSaveError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dressingNewGarment),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
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
                                child: const Icon(Icons.close,
                                    size: 16, color: AppColors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined,
                              size: 40, color: AppColors.textHint),
                          const SizedBox(height: 8),
                          Text(l10n.garmentAddPhotoCaption,
                              style: AppTextStyles.caption),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _nameController,
              decoration:
                  InputDecoration(hintText: l10n.garmentNameDescHint),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brandController,
              decoration: InputDecoration(hintText: l10n.garmentBrandHint),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _colorController,
              decoration: InputDecoration(hintText: l10n.garmentColorHint),
            ),
            const SizedBox(height: 24),
            Text(l10n.garmentCategoryTitle, style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final selected = _selectedCategory == cat.key;
                return ChoiceChip(
                  label: Text(categoryLabelL10n(l10n, cat.key)),
                  avatar: GarmentCategoryGlyph(
                    categoryKey: cat.key,
                    color:
                        selected ? AppColors.white : AppColors.textSecondary,
                    size: 18,
                  ),
                  selected: selected,
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color:
                        selected ? AppColors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat.key),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : Text(l10n.commonSave),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
