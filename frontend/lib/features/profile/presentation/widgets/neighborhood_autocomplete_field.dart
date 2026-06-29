import 'dart:async';

import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/games/data/game_repository.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/profile/presentation/widgets/location_selected_row.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Type-ahead neighbourhood / street picker scoped to a selected city.
/// Emits only the resolved neighbourhood name string.
class NeighborhoodAutocompleteField extends ConsumerStatefulWidget {
  const NeighborhoodAutocompleteField({
    super.key,
    required this.selectedCity,
    required this.selectedNeighborhood,
    required this.onNeighborhoodSelected,
    this.label = 'Neighbourhood',
    this.hint = 'Start typing an area or street…',
  });

  final String? selectedCity;
  final String? selectedNeighborhood;
  final ValueChanged<String> onNeighborhoodSelected;
  final String label;
  final String hint;

  @override
  ConsumerState<NeighborhoodAutocompleteField> createState() =>
      _NeighborhoodAutocompleteFieldState();
}

class _NeighborhoodAutocompleteFieldState
    extends ConsumerState<NeighborhoodAutocompleteField> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;
  bool _isFetching = false;
  bool _isResolving = false;
  bool _isEditing = false;
  List<AddressSuggestion> _suggestions = const [];

  bool get _hasCity =>
      widget.selectedCity != null && widget.selectedCity!.trim().isNotEmpty;

  bool get _hasValue =>
      widget.selectedNeighborhood != null &&
      widget.selectedNeighborhood!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _isEditing = _hasCity && !_hasValue;
  }

  @override
  void didUpdateWidget(NeighborhoodAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCity != widget.selectedCity) {
      _debounce?.cancel();
      _searchCtrl.clear();
      setState(() {
        _suggestions = const [];
        _isFetching = false;
        _isEditing = _hasCity && !_hasValue;
      });
    } else if (oldWidget.selectedNeighborhood != widget.selectedNeighborhood &&
        _hasValue) {
      _debounce?.cancel();
      _searchCtrl.clear();
      setState(() {
        _isEditing = false;
        _suggestions = const [];
        _isFetching = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (!_hasCity) return;
    setState(() {
      _isEditing = true;
      _suggestions = const [];
    });
  }

  void _exitEditing() {
    _debounce?.cancel();
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _isEditing = false;
      _suggestions = const [];
      _isFetching = false;
    });
  }

  Future<void> _onQueryChanged(String value) async {
    if (!_hasCity) return;

    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = const [];
        _isFetching = false;
      });
      return;
    }

    final scopedQuery = '$query, ${widget.selectedCity!.trim()}';

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final id = ++_requestId;
      setState(() => _isFetching = true);
      try {
        final suggestions = await ref.read(gameRepositoryProvider).autocompleteAddress(
              scopedQuery,
              types: 'address',
            );
        if (!mounted || id != _requestId) return;
        setState(() => _suggestions = suggestions);
      } catch (_) {
        if (!mounted || id != _requestId) return;
        setState(() => _suggestions = const []);
      } finally {
        if (mounted && id == _requestId) {
          setState(() => _isFetching = false);
        }
      }
    });
  }

  String _resolveNeighborhoodName(
    GameLocation location,
    AddressSuggestion suggestion,
  ) {
    final city = widget.selectedCity?.trim().toLowerCase() ?? '';
    final hood = location.neighborhood?.trim();
    if (hood != null &&
        hood.isNotEmpty &&
        hood.toLowerCase() != city) {
      return hood;
    }

    final primary = suggestion.primaryText?.trim();
    if (primary != null && primary.isNotEmpty) return primary;

    return hood ?? suggestion.description.split(',').first.trim();
  }

  Future<void> _selectSuggestion(AddressSuggestion suggestion) async {
    if (!_hasCity) return;

    FocusScope.of(context).unfocus();
    setState(() => _isResolving = true);
    try {
      final location =
          await ref.read(gameRepositoryProvider).getPlaceDetails(suggestion.placeId);
      if (!mounted) return;
      _searchCtrl.clear();
      setState(() {
        _suggestions = const [];
        _isEditing = false;
      });
      widget.onNeighborhoodSelected(_resolveNeighborhoodName(location, suggestion));
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, context.l10n.placeCouldNotResolve);
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  Widget _buildEditMode() {
    return Column(
      key: const ValueKey('neighborhood-edit'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasValue)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _exitEditing,
              child: Text(context.l10n.cancel),
            ),
          ),
        BbTextField(
          label: widget.label,
          hint: widget.hint,
          controller: _searchCtrl,
          prefixIcon: Icons.search_rounded,
          autofocus: _isEditing,
          onChanged: _onQueryChanged,
        ),
        if (_isFetching || _isResolving) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _NeighborhoodSuggestionsList(
            suggestions: _suggestions,
            onSelect: _selectSuggestion,
          ),
        ],
      ],
    );
  }

  Widget _buildViewMode() {
    return Column(
      key: const ValueKey('neighborhood-view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 6),
        LocationSelectedRow(
          icon: Icons.map_rounded,
          value: widget.selectedNeighborhood!,
          onEdit: _startEditing,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCity) {
      return LocationDisabledHint(
        label: widget.label,
        message: 'Please select a city first',
        icon: Icons.map_rounded,
      );
    }

    final showView = _hasValue && !_isEditing;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: showView ? _buildViewMode() : _buildEditMode(),
    );
  }
}

class _NeighborhoodSuggestionsList extends StatelessWidget {
  const _NeighborhoodSuggestionsList({
    required this.suggestions,
    required this.onSelect,
  });

  final List<AddressSuggestion> suggestions;
  final void Function(AddressSuggestion) onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: suggestions.take(6).map((suggestion) {
            return ListTile(
              dense: true,
              leading: const Icon(
                Icons.place_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              title: Text(
                suggestion.primaryText ?? suggestion.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: (suggestion.secondaryText ?? '').isEmpty
                  ? null
                  : Text(
                      suggestion.secondaryText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              onTap: () => onSelect(suggestion),
            );
          }).toList(),
        ),
      ),
    );
  }
}
