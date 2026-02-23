import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/color_service.dart';

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
  final FocusNode _focusNode = FocusNode();
  ColorOption? _selectedColor;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      widget.controller.text = widget.initialValue!;
      _findColorByName(widget.initialValue!);
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Délai pour permettre aux clics sur la liste de se terminer
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
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
        _suggestions = [];
        _showSuggestions = false;
        _selectedColor = null;
      });
      return;
    }

    final matches = ColorService.searchColors(value);
    setState(() {
      _suggestions = matches;
      _showSuggestions = matches.isNotEmpty && _focusNode.hasFocus;
      _findColorByName(value);
    });
  }

  void _selectColor(ColorOption color) {
    widget.controller.text = color.name;
    setState(() {
      _selectedColor = color;
      _showSuggestions = false;
    });
    // Délai pour permettre au clic de se terminer avant de perdre le focus
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: _onTextChanged,
          onTap: () {
            if (widget.controller.text.isNotEmpty) {
              _onTextChanged(widget.controller.text);
            } else {
              setState(() {
                _suggestions = ColorService.getColors().take(20).toList();
                _showSuggestions = true;
              });
            }
          },
          decoration: InputDecoration(
            hintText: 'Couleur',
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
                          color: _selectedColor!.color == Colors.white ||
                                  _selectedColor!.color == Colors.transparent
                              ? AppColors.divider
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() {
                        _suggestions = [];
                        _showSuggestions = false;
                        _selectedColor = null;
                      });
                    },
                  )
                : null,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
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
                    color: Colors.black.withOpacity(0.1),
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
                                color: colorOption.color == Colors.white ||
                                        colorOption.color == Colors.transparent
                                    ? AppColors.divider
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
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
                                            Colors.red,
                                            Colors.orange,
                                            Colors.yellow,
                                            Colors.green,
                                            Colors.blue,
                                            Colors.indigo,
                                            Colors.purple,
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
            widget.controller.text.isNotEmpty &&
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
    );
  }
}
