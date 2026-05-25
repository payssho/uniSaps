import 'package:flutter/material.dart';
import '../l10n/l10n_context.dart';
import '../core/constants/app_colors.dart';
import '../services/color_service.dart';

class MultiColorSelector extends StatefulWidget {
  final List<String> initialColors;
  final Function(List<String>) onColorsChanged;

  const MultiColorSelector({
    super.key,
    this.initialColors = const [],
    required this.onColorsChanged,
  });

  @override
  State<MultiColorSelector> createState() => _MultiColorSelectorState();
}

class _MultiColorSelectorState extends State<MultiColorSelector> {
  List<ColorOption> _selectedColors = [];
  List<ColorOption> _suggestions = [];
  bool _showSuggestions = false;
  /// false = 1er tap : liste visible sans clavier · true = 2e tap : saisie / filtre.
  bool _isSearchMode = false;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  /// Regroupe champ + liste : tap ailleurs sur le formulaire ferme le picker sans confondre avec le scroll dans la liste.
  final Object _pickerTapGroup = Object();

  void _onFocusNodeChanged() {
    // Ne pas fermer la liste au blur en mode browse : le scroll du dropdown enlève souvent le focus du TextField.
    if (!_focusNode.hasFocus && _isSearchMode) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() {
            _showSuggestions = false;
            _isSearchMode = false;
          });
        }
      });
    }
  }

  void _closePickerFromOutside() {
    if (!_showSuggestions) return;
    setState(() {
      _showSuggestions = false;
      _isSearchMode = false;
    });
    _focusNode.unfocus();
  }

  void _handleTap() {
    final blocked = _selectedColors.length >= 3 &&
        !_selectedColors.any((c) => c.name.toLowerCase() == 'multicolore');
    if (blocked) return;

    if (!_showSuggestions) {
      setState(() {
        _suggestions = ColorService.quickPickColors();
        _showSuggestions = true;
        _isSearchMode = false;
      });
    } else if (!_isSearchMode) {
      setState(() => _isSearchMode = true);
      Future.microtask(() {
        if (mounted) {
          _focusNode.unfocus();
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) _focusNode.requestFocus();
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialColors.isNotEmpty) {
      _loadInitialColors();
    }
    _focusNode.addListener(_onFocusNodeChanged);
  }

  @override
  void didUpdateWidget(covariant MultiColorSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSet = oldWidget.initialColors.map((e) => e.toLowerCase()).toSet();
    final newSet = widget.initialColors.map((e) => e.toLowerCase()).toSet();
    if (oldSet.length != newSet.length || !oldSet.containsAll(newSet)) {
      _loadInitialColors();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusNodeChanged);
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialColors() {
    final allColors = ColorService.getColors();
    _selectedColors = widget.initialColors
        .map((colorName) => allColors.firstWhere(
              (c) => c.name.toLowerCase() == colorName.toLowerCase(),
              orElse: () => const ColorOption(name: '', color: Colors.transparent),
            ))
        .where((c) => c.name.isNotEmpty)
        .toList();
  }

  void _onSearchChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _suggestions = ColorService.quickPickColors();
        _showSuggestions = _focusNode.hasFocus;
      });
      return;
    }

    final matches = ColorService.searchColors(value);
    setState(() {
      _suggestions = matches;
      _showSuggestions = matches.isNotEmpty && _focusNode.hasFocus;
    });
  }

  void _addColor(ColorOption color) {
    if (_selectedColors.length >= 3 && color.name.toLowerCase() != 'multicolore') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.garmentMaxThreeColors),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Si "Multicolore" est sélectionné, remplacer toutes les couleurs
    if (color.name.toLowerCase() == 'multicolore') {
      setState(() {
        _selectedColors = [color];
        _showSuggestions = false;
        _isSearchMode = false;
      });
      widget.onColorsChanged(['Multicolore']);
      _searchController.clear();
      _focusNode.unfocus();
      return;
    }

    // Vérifier si la couleur n'est pas déjà sélectionnée
    if (_selectedColors.any((c) => c.name == color.name)) {
      return;
    }

    // Si "Multicolore" était sélectionné, le remplacer
    if (_selectedColors.any((c) => c.name.toLowerCase() == 'multicolore')) {
      setState(() {
        _selectedColors = [color];
      });
    } else {
      setState(() {
        _selectedColors.add(color);
      });
    }

    widget.onColorsChanged(_selectedColors.map((c) => c.name).toList());
    _searchController.clear();
    setState(() {
      _showSuggestions = false;
      _isSearchMode = false;
    });
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _focusNode.unfocus();
    });
  }

  void _removeColor(ColorOption color) {
    setState(() {
      _selectedColors.removeWhere((c) => c.name == color.name);
    });
    widget.onColorsChanged(_selectedColors.map((c) => c.name).toList());
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _pickerTapGroup,
      onTapOutside: (_) => _closePickerFromOutside(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Couleurs sélectionnées
        if (_selectedColors.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedColors.map((colorOption) {
              return Chip(
                avatar: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorOption.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorOption.color == AppColors.white ||
                              colorOption.color == Colors.transparent
                          ? AppColors.divider
                          : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.graphite.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: colorOption.color == Colors.transparent
                      ? Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.graphite,
                                  AppColors.stormyTeal,
                                  AppColors.white,
                                  AppColors.alabasterGrey,
                                  AppColors.yaleBlue,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                label: Text(colorOption.name),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeColor(colorOption),
                backgroundColor: AppColors.surfaceVariant,
                side: const BorderSide(color: AppColors.divider),
              );
            }).toList(),
          ),
        if (_selectedColors.isNotEmpty) const SizedBox(height: 12),
        // Champ de recherche
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          scrollPadding: EdgeInsets.zero,
          readOnly: !_isSearchMode,
          onChanged: _isSearchMode ? _onSearchChanged : null,
          onTap: _handleTap,
          decoration: InputDecoration(
            hintText: _selectedColors.length >= 3
                ? 'Maximum 3 couleurs atteint'
                : _showSuggestions && !_isSearchMode
                    ? 'Appuie à nouveau pour filtrer…'
                    : 'Rechercher ou choisir une couleur (max 3)',
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.palette_outlined, size: 22, color: AppColors.textHint),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _suggestions = ColorService.quickPickColors();
                        _showSuggestions = true;
                      });
                    },
                  )
                : null,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          enabled: _selectedColors.length < 3 || _selectedColors.any((c) => c.name.toLowerCase() == 'multicolore'),
        ),
        // Suggestions
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.graphite.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider.withOpacity(0.5),
              ),
              itemBuilder: (context, index) {
                final colorOption = _suggestions[index];
                final isSelected = _selectedColors.any((c) => c.name == colorOption.name);
                return InkWell(
                  onTap: isSelected ? null : () => _addColor(colorOption),
                  child: Opacity(
                    opacity: isSelected ? 0.5 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colorOption.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorOption.color == AppColors.white ||
                                        colorOption.color == Colors.transparent
                                    ? AppColors.divider
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.graphite.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: colorOption.color == Colors.transparent
                                ? Center(
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.graphite,
                                            AppColors.stormyTeal,
                                            AppColors.white,
                                            AppColors.alabasterGrey,
                                            AppColors.yaleBlue,
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              colorOption.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (_showSuggestions &&
            _suggestions.isEmpty &&
            _searchController.text.isNotEmpty &&
            _isSearchMode &&
            _focusNode.hasFocus)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aucune couleur trouvée. Tu peux saisir librement.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
