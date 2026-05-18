import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/categories.dart';
import '../../models/collection_model.dart';
import '../../models/garment_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/creator_post_provider.dart';
import '../../providers/garment_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../widgets/creator_post_preview_sheet.dart';

class CreatorPostCreateSheet extends ConsumerStatefulWidget {
  const CreatorPostCreateSheet({super.key});

  @override
  ConsumerState<CreatorPostCreateSheet> createState() =>
      _CreatorPostCreateSheetState();
}

class _CreatorPostCreateSheetState extends ConsumerState<CreatorPostCreateSheet> {
  final _captionController = TextEditingController();
  final Map<String, String> _selected = {};
  final Map<String, GarmentModel> _selectedGarments = {};
  String? _collectionId;
  Uint8List? _previewBytes;
  String? _previewName;
  bool _isActive = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickPreview() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 90,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _previewBytes = bytes;
      _previewName = picked.name;
    });
  }

  Future<void> _pickGarment(String zoneKey, String catKey) async {
    final uid = ref.read(authServiceProvider).uid;
    final garments = ref.read(garmentsProvider(uid)).valueOrNull ?? [];
    final filtered = _collectionId == null
        ? garments
        : garments.where((g) => g.collectionId == _collectionId).toList();
    if (!mounted) return;
    final picked = await showModalBottomSheet<GarmentModel>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final g = filtered[i];
            return ListTile(
              title: Text(g.name),
              subtitle: Text(g.brand),
              onTap: () => Navigator.pop(ctx, g),
            );
          },
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _selected[zoneKey] = picked.id;
      _selectedGarments[zoneKey] = picked;
    });
  }

  Future<void> _previewFeed() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || _previewBytes == null) {
      setState(() => _error = 'Ajoute une image de preview.');
      return;
    }
    final refs = _selectedGarments.values
        .map((g) => GarmentRef(name: g.name, brand: g.brand))
        .toList();
    final post = buildPreviewPost(
      brand: user,
      imageUrl: 'https://placeholder.local/preview.jpg',
      refs: refs,
      caption: _captionController.text.trim(),
    );
    if (!mounted) return;
    await CreatorPostPreviewSheet.show(context, post);
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
    if (_selected.isEmpty) {
      setState(() => _error = 'Ajoute au moins une pièce au look.');
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
          name: 'Post pub ${DateTime.now().millisecondsSinceEpoch}',
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

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).uid;
    final collectionsAsync = ref.watch(collectionsProvider(uid));
    final zones = [
      ('head', 'Tête', Icons.face_rounded, 'headwear'),
      ('torso', 'Haut', Icons.checkroom_rounded, 'top'),
      ('jacket', 'Veste', Icons.dry_cleaning_rounded, 'outerwear'),
      ('legs', 'Bas', Icons.accessibility_new_rounded, 'bottom'),
      ('feet', 'Chaussures', Icons.ice_skating_rounded, 'shoes'),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, scrollController) => Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Nouveau post pub', style: AppTextStyles.heading2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  collectionsAsync.when(
                    data: (cols) {
                      final sorted = List<CollectionModel>.from(cols)
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      return DropdownButtonFormField<String>(
                        value: _collectionId,
                        decoration: const InputDecoration(
                          labelText: 'Collection',
                          border: OutlineInputBorder(),
                        ),
                        items: sorted
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _collectionId = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Visible dans le feed (actif)'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickPreview,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_previewBytes == null
                        ? 'Image preview (obligatoire)'
                        : 'Preview sélectionnée'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pièces du look', style: AppTextStyles.heading3),
                  ...zones.map((z) {
                    final (zoneKey, label, icon, catKey) = z;
                    final garment = _selectedGarments[zoneKey];
                    return ListTile(
                      leading: Icon(icon),
                      title: Text(label),
                      subtitle: Text(garment?.name ?? 'Non sélectionné'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickGarment(zoneKey, catKey),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _captionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Légende (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 20),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
