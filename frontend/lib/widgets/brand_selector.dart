import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../l10n/l10n_context.dart';
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
  bool _isSearchMode = false;
  final FocusNode _focusNode = FocusNode();
  final Object _pickerTapGroup = Object();

  @override
  void initState() {
    super.initState();
    _loadBrands();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
    _focusNode.addListener(() {
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
        _suggestions = _allBrands.take(20).toList();
        _showSuggestions = _focusNode.hasFocus;
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
      _isSearchMode = false;
    });
    // Délai pour permettre au clic de se terminer avant de perdre le focus
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.unfocus();
      }
    });
  }

  void _handleBrandTap() {
    if (!_showSuggestions) {
      setState(() {
        if (widget.controller.text.isNotEmpty) {
          final matches =
              BrandService.searchBrands(widget.controller.text, _allBrands);
          _suggestions = matches;
          _showSuggestions = matches.isNotEmpty;
        } else {
          _suggestions = _allBrands.take(20).toList();
          _showSuggestions = _suggestions.isNotEmpty;
        }
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

  void _closePickerFromOutside() {
    if (!_showSuggestions) return;
    setState(() {
      _showSuggestions = false;
      _isSearchMode = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _pickerTapGroup,
      onTapOutside: (_) => _closePickerFromOutside(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          readOnly: !_isSearchMode,
          onChanged: _isSearchMode ? _onTextChanged : null,
          scrollPadding: EdgeInsets.zero,
          onTap: _handleBrandTap,
          decoration: InputDecoration(
            hintText: _showSuggestions && !_isSearchMode
                ? context.l10n.garmentBrandTapAgainToFilter
                : context.l10n.garmentBrandHint,
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
                            _isSearchMode = false;
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
        if (_showSuggestions &&
            _suggestions.isEmpty &&
            widget.controller.text.isNotEmpty &&
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
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.garmentBrandNoneFound,
                    style: const TextStyle(
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
