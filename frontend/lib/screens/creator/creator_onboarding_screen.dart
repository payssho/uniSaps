import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garment_provider.dart';
import '../../l10n/l10n_context.dart';
class CreatorOnboardingScreen extends ConsumerStatefulWidget {
  const CreatorOnboardingScreen({super.key});

  @override
  ConsumerState<CreatorOnboardingScreen> createState() =>
      _CreatorOnboardingScreenState();
}

class _CreatorOnboardingScreenState extends ConsumerState<CreatorOnboardingScreen> {
  final _brandNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _shopController = TextEditingController();
  final _linkedUsernameController = TextEditingController();
  Uint8List? _logoBytes;
  String? _logoName;
  bool _loading = false;

  @override
  void dispose() {
    _brandNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _shopController.dispose();
    _linkedUsernameController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _logoBytes = bytes;
      _logoName = picked.name;
    });
  }

  Future<void> _submit() async {
    final brand = _brandNameController.text.trim();
    final username = _usernameController.text.trim();
    final l10n = context.l10n;
    if (brand.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.creatorOnboardingBrandRequired)),
      );
      return;
    }
    if (_logoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.creatorOnboardingLogoRequired)),
      );
      return;
    }

    setState(() => _loading = true);
    final uid = ref.read(authServiceProvider).uid;
    var logoUrl = '';
    try {
      logoUrl = await ref.read(storageServiceProvider).uploadProfilePhotoBytes(
            _logoBytes!,
            uid,
            _logoName ?? 'logo.jpg',
          );
    } catch (_) {}

    var linkedUid = '';
    final linkedUsername = _linkedUsernameController.text.trim();
    if (linkedUsername.isNotEmpty) {
      final results =
          await ref.read(firestoreServiceProvider).searchUsers(linkedUsername);
      final match = results.where((u) => u.username == linkedUsername).firstOrNull;
      linkedUid = match?.uid ?? '';
    }

    await ref.read(authNotifierProvider.notifier).completeCreatorOnboarding(
          username: username,
          displayName: brand,
          creatorBio: _bioController.text.trim(),
          creatorShopUrl: _shopController.text.trim(),
          creatorLogoUrl: logoUrl,
          linkedUserUid: linkedUid,
        );

    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/creator/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.creatorOnboardingTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickLogo,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage:
                      _logoBytes != null ? MemoryImage(_logoBytes!) : null,
                  child: _logoBytes == null
                      ? const Icon(Icons.add_a_photo_outlined, size: 28)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.creatorLogoLabel, style: AppTextStyles.bodySecondary),
              const SizedBox(height: 24),
              TextField(
                controller: _brandNameController,
                decoration: InputDecoration(hintText: l10n.creatorBrandName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(hintText: l10n.creatorPublicId),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(hintText: l10n.creatorBio),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _shopController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(hintText: l10n.creatorShopUrl),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkedUsernameController,
                decoration: InputDecoration(hintText: l10n.creatorPersonalAccount),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.creatorOnboardingFinish),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
