import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/garment_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/platform_image.dart';

class InspirationScreen extends ConsumerStatefulWidget {
  const InspirationScreen({super.key});

  @override
  ConsumerState<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends ConsumerState<InspirationScreen> {
  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);
    final uid = ref.watch(authServiceProvider).uid;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text('Inspiration', style: AppTextStyles.heading2),
            ),
            Expanded(
              child: postsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.explore_outlined, size: 72, color: AppColors.textHint.withOpacity(0.3)),
                          const SizedBox(height: 20),
                          const Text('Aucun post', style: AppTextStyles.bodySecondary),
                          const SizedBox(height: 6),
                          const Text('Sois le premier a partager !', style: AppTextStyles.caption),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 18),
                    itemBuilder: (_, i) => PostCard(
                      post: posts[i],
                      currentUid: uid,
                      onLike: () {
                        ref.read(postNotifierProvider.notifier).toggleLike(posts[i].id, uid);
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton.extended(
          heroTag: 'inspiration_fab',
          backgroundColor: AppColors.accent,
          elevation: 6,
          onPressed: () => _showPublishSheet(context),
          icon: const Icon(Icons.add, color: Colors.white, size: 24),
          label: const Text('Publier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _showPublishSheet(BuildContext context) {
    final captionController = TextEditingController();
    XFile? imageFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouveau post', style: AppTextStyles.heading3),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      setSheetState(() => imageFile = picked);
                    }
                  },
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageFile != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              PlatformImage(file: imageFile!, fit: BoxFit.cover),
                              Positioned(
                                top: 6, right: 6,
                                child: GestureDetector(
                                  onTap: () => setSheetState(() => imageFile = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textHint),
                              SizedBox(height: 6),
                              Text('Ajouter une photo', style: AppTextStyles.caption),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: captionController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(hintText: 'Legende...'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (imageFile == null) return;
                      final user = ref.read(currentUserProvider).valueOrNull;
                      if (user == null) return;
                      Navigator.pop(ctx);
                      final bytes = await imageFile!.readAsBytes();
                      await ref.read(postNotifierProvider.notifier).createPost(
                            userId: user.uid,
                            username: user.username,
                            userPhotoUrl: user.profilePhotoUrl,
                            imageBytes: bytes,
                            imageName: imageFile!.name,
                            caption: captionController.text.trim(),
                          );
                    },
                    child: const Text('Publier'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
