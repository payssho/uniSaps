import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/color_service.dart';
import '../l10n/l10n_context.dart';

class ColorSelector extends StatefulWidget {
  final TextEditingController controller;
  final String? initialValue;

  const ColorSelector({
    super.key,
    required this.controller,
    this.initialValue,
  });

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  List<ColorOption> _suggestions = [];
  bool _showSuggestions = false;
  // false = 1er tap (dropdown visible, sans clavier)
  // true  = 2ème tap (clavier visible pour filtrer)
  bool _isSearchMode = false;
  final FocusNode _focusNode = FocusNode();
  ColorOption? _selectedColor;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      widget.controller.text = widget.initialValue!;
      _findColorByName(widget.initialValue!);
    }
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
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

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _findColorByName(String name) {
    final colors = ColorService.getColors();
    final found = colors.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => const ColorOption(name: '', color: Colors.transparent),
    );
    if (found.name.isNotEmpty) {
      setState(() => _selectedColor = found);
    }
  }

  void _onTextChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _suggestions = ColorService.quickPickColors();
        _showSuggestions = true;
        _selectedColor = null;
      });
      return;
    }
    final matches = ColorService.searchColors(value);
    setState(() {
      _suggestions = matches;
      _showSuggestions = true;
    });
    _findColorByName(value);
  }

  void _selectColor(ColorOption color) {
    widget.controller.text = color.name;
    setState(() {
      _selectedColor = color;
      _showSuggestions = false;
      _isSearchMode = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _focusNode.unfocus();
    });
  }

  void _onTap() {
    if (!_showSuggestions) {
      // 1er tap : ouvrir le dropdown sans afficher le clavier
      setState(() {
        _suggestions = ColorService.quickPickColors();
        _showSuggestions = true;
        _isSearchMode = false;
      });
    } else if (!_isSearchMode) {
      // 2ème tap : activer la recherche et afficher le clavier
      setState(() => _isSearchMode = true);
      // Forcer l'affichage du clavier
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          // Clavier masqué en mode browse (1er tap), visible en mode search (2ème tap)
          readOnly: !_isSearchMode,
          onChanged: _isSearchMode ? _onTextChanged : null,
          onTap: _onTap,
          decoration: InputDecoration(
            hintText: _showSuggestions && !_isSearchMode
                ? 'Appuie à nouveau pour filtrer…'
                : 'Couleur',
            prefixIcon: _selectedColor != null && _selectedColor!.name.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _selectedColor!.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor!.color == AppColors.white ||
                                  _selectedColor!.color == Colors.transparent
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
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.palette_outlined, size: 22, color: AppColors.textHint),
                  ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() {
                        _suggestions = [];
                        _showSuggestions = false;
                        _isSearchMode = false;
                        _selectedColor = null;
                      });
                      _focusNode.unfocus();
                    },
                  )
                : _showSuggestions
                    ? IconButton(
                        icon: const Icon(Icons.keyboard_outlined, size: 20, color: AppColors.textHint),
                        tooltip: context.l10n.colorFilterTypeHint,
                        onPressed: _onTap,
                      )
                    : null,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        // Indication visuelle du mode actif
        if (_showSuggestions && !_isSearchMode)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                const Icon(Icons.touch_app_outlined, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'Appuie à nouveau sur le champ pour filtrer',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Material(
            color: Colors.transparent,
            child: Container(
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
                  return InkWell(
                    onTap: () => _selectColor(colorOption),
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (_showSuggestions &&
            _suggestions.isEmpty &&
            widget.controller.text.isNotEmpty)
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
    );
  }
}
