import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/categories.dart';
import '../../models/garment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garment_provider.dart';
import '../../widgets/garment_card.dart';
import '../../widgets/category_chip.dart';
import 'add_garment_screen.dart';

class DressingScreen extends ConsumerStatefulWidget {
  const DressingScreen({super.key});

  @override
  ConsumerState<DressingScreen> createState() => _DressingScreenState();
}

class _DressingScreenState extends ConsumerState<DressingScreen> {
  String _selectedCategory = '';

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).uid;
    final garmentsAsync = ref.watch(garmentsProvider(uid));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Mon Dressing', style: AppTextStyles.heading2),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  children: [
                    CategoryChip(
                      label: 'Tout',
                      icon: Icons.grid_view_rounded,
                      selected: _selectedCategory.isEmpty,
                      onTap: () => setState(() => _selectedCategory = ''),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CategoryChip(
                            label: cat.label,
                            icon: cat.icon,
                            selected: _selectedCategory == cat.key,
                            onTap: () => setState(() => _selectedCategory = cat.key),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: garmentsAsync.when(
                  data: (garments) {
                    final filtered = _selectedCategory.isEmpty
                        ? garments
                        : garments.where((g) => g.category == _selectedCategory).toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.checkroom, size: 72, color: AppColors.textHint.withOpacity(0.3)),
                            const SizedBox(height: 20),
                            const Text('Aucun vetement', style: AppTextStyles.bodySecondary),
                            const SizedBox(height: 6),
                            const Text('Ajoute ton premier vetement !', style: AppTextStyles.caption),
                          ],
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => GarmentCard(
                        garment: filtered[i],
                        onLongPress: () => _confirmDelete(filtered[i]),
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
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton.extended(
          heroTag: 'dressing_fab',
          backgroundColor: AppColors.accent,
          elevation: 6,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddGarmentScreen()),
            );
          },
          icon: const Icon(Icons.add, color: Colors.white, size: 24),
          label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _confirmDelete(GarmentModel garment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Supprimer "${garment.name}" ?', style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () {
                        final uid = ref.read(authServiceProvider).uid;
                        ref.read(garmentNotifierProvider.notifier).deleteGarment(uid, garment.id);
                        Navigator.pop(context);
                      },
                      child: const Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
