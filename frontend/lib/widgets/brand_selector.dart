import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/brand_service.dart';

class BrandSelector extends StatefulWidget {
  final TextEditingController controller;
  final String? initialValue;

  const BrandSelector({
    super.key,
    required this.controller,
    this.initialValue,
  });

  @override
  State<BrandSelector> createState() => _BrandSelectorState();
}

class _BrandSelectorState extends State<BrandSelector> {
  List<String> _allBrands = [];
  List<String> _suggestions = [];
  bool _isLoading = true;
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadBrands();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
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

  Future<void> _loadBrands() async {
    final brands = await BrandService.getBrands();
    setState(() {
      _allBrands = brands;
      _isLoading = false;
    });
  }

  void _onTextChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final matches = BrandService.searchBrands(value, _allBrands);
    setState(() {
      _suggestions = matches;
      _showSuggestions = matches.isNotEmpty && _focusNode.hasFocus;
    });
  }

  void _selectBrand(String brand) {
    widget.controller.text = brand;
    setState(() {
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
            }
          },
          decoration: InputDecoration(
            hintText: 'Marque',
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          widget.controller.clear();
                          setState(() {
                            _suggestions = [];
                            _showSuggestions = false;
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
                    color: AppColors.graphite.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 200),
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
                  final brand = _suggestions[index];
                  return InkWell(
                    onTap: () => _selectBrand(brand),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        brand,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (_showSuggestions && _suggestions.isEmpty && widget.controller.text.isNotEmpty && _focusNode.hasFocus)
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
                    'Aucune marque trouvée. Tu peux saisir librement.',
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
