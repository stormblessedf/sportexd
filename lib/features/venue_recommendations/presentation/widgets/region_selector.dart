import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/location_data.dart';
import 'package:sporsal/core/models/place_autocomplete_result.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Signature for autocomplete fetching — allows test injection without
/// importing the web-only [PlacesService].
typedef AutocompleteFetcher = Future<List<PlaceAutocompleteResult>> Function(
    String query);

/// Signature for place-detail fetching.
typedef PlaceDetailFetcher = Future<LocationData?> Function(String placeId);

/// Signature for current-location fetching.
typedef CurrentLocationFetcher = Future<LocationData?> Function();

/// Region selector widget with text-based location search and current location
/// support.
///
/// Provides autocomplete suggestions via [PlacesService] and a
/// "Mevcut Konumumu Kullan" button to use the device's current location.
///
/// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
class RegionSelector extends StatefulWidget {
  const RegionSelector({
    super.key,
    required this.onRegionSelected,
    required this.autocompleteFetcher,
    required this.placeDetailFetcher,
    required this.currentLocationFetcher,
    this.onRegionNameChanged,
  });

  /// Called when a region is selected (autocomplete or current location).
  final ValueChanged<LocationData> onRegionSelected;

  /// Optional callback for display name of the selected region.
  final ValueChanged<String>? onRegionNameChanged;

  /// Fetches autocomplete suggestions for a query string.
  final AutocompleteFetcher autocompleteFetcher;

  /// Fetches place details (coordinates) for a given place ID.
  final PlaceDetailFetcher placeDetailFetcher;

  /// Fetches the device's current location. Returns null when permission
  /// is denied or the location service is unavailable.
  final CurrentLocationFetcher currentLocationFetcher;

  @override
  State<RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<RegionSelector> {
  late final AutocompleteFetcher _fetchAutocomplete;
  late final PlaceDetailFetcher _fetchPlaceDetail;
  late final CurrentLocationFetcher _fetchCurrentLocation;

  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  List<PlaceAutocompleteResult> _suggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isLoadingLocation = false;
  String? _permissionDeniedMessage;
  bool _regionSelected = false;

  static const _debounceDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _fetchAutocomplete = widget.autocompleteFetcher;
    _fetchPlaceDetail = widget.placeDetailFetcher;
    _fetchCurrentLocation = widget.currentLocationFetcher;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onSearchChanged(String query) {
    _permissionDeniedMessage = null;
    _regionSelected = false;

    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    _debounce = Timer(_debounceDuration, () async {
      final results = await _fetchAutocomplete(query.trim());
      if (mounted && _searchController.text.trim() == query.trim()) {
        setState(() {
          _suggestions = results;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  Future<void> _onSuggestionTap(PlaceAutocompleteResult suggestion) async {
    _focusNode.unfocus();
    setState(() {
      _searchController.text = suggestion.description;
      _suggestions = [];
      _isLoadingSuggestions = true;
    });

    final location = await _fetchPlaceDetail(suggestion.placeId);
    if (!mounted) return;

    setState(() => _isLoadingSuggestions = false);

    if (location != null) {
      _regionSelected = true;
      widget.onRegionNameChanged?.call(suggestion.mainText);
      widget.onRegionSelected(location);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _permissionDeniedMessage = null;
    });

    final location = await _fetchCurrentLocation();
    if (!mounted) return;

    setState(() => _isLoadingLocation = false);

    if (location == null) {
      setState(() {
        _permissionDeniedMessage =
            'Konum izni reddedildi. Lütfen manuel olarak konum girin.';
      });
      _focusNode.requestFocus();
      return;
    }

    _searchController.text = location.address ?? 'Mevcut Konum';
    _regionSelected = true;
    _suggestions = [];
    widget.onRegionNameChanged?.call(location.address ?? 'Mevcut Konum');
    widget.onRegionSelected(location);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCurrentLocationButton(),
        const SizedBox(height: 16),
        _buildSearchField(),
        if (_permissionDeniedMessage != null) ...[
          const SizedBox(height: 12),
          _buildPermissionDeniedBanner(),
        ],
        if (_isLoadingSuggestions && !_regionSelected)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        if (_suggestions.isNotEmpty && !_regionSelected)
          _buildSuggestionsList(),
      ],
    );
  }

  Widget _buildCurrentLocationButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoadingLocation ? null : _useCurrentLocation,
        icon: _isLoadingLocation
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.my_location, size: 20),
        label: Text(
          _isLoadingLocation ? 'Konum alınıyor...' : 'Mevcut Konumumu Kullan',
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      onChanged: _onSearchChanged,
      style: GoogleFonts.lexend(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: 'Konum ara...',
        hintStyle: GoogleFonts.lexend(
          fontSize: 14,
          color: AppColors.textLight,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textMuted,
          size: 20,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                color: AppColors.textMuted,
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                  _focusNode.requestFocus();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _permissionDeniedMessage!,
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 240),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 48,
          color: AppColors.borderLight,
        ),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return _SuggestionTile(
            suggestion: suggestion,
            onTap: () => _onSuggestionTap(suggestion),
          );
        },
      ),
    );
  }
}

/// Individual autocomplete suggestion row.
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  final PlaceAutocompleteResult suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.mainText,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (suggestion.secondaryText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.secondaryText,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
