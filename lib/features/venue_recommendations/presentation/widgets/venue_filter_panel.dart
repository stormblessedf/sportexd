import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/venue_filter_state.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Bottom sheet filter panel for venue recommendations.
///
/// Provides controls for:
/// - Indoor/outdoor environment toggle (İç/Dış mekan)
/// - Price level multi-select chips (Ücretsiz, ₺–₺₺₺₺)
/// - Minimum rating slider (0.0–5.0, step 0.5)
/// - Maximum distance single-select chips (1–20 km, Sınırsız)
/// - "Şu An Açık" (Currently Open) switch
/// - Active filter count badge
/// - "Filtreleri Temizle" (Clear Filters) + "Uygula" (Apply) buttons
///
/// Validates: Requirements 8.1, 8.2, 8.3, 8.4, 8.5, 8.7, 8.8, 8.9
class VenueFilterPanel extends StatefulWidget {
  const VenueFilterPanel({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  final VenueFilterState currentFilter;
  final ValueChanged<VenueFilterState> onFilterChanged;

  @override
  State<VenueFilterPanel> createState() => _VenueFilterPanelState();
}

class _VenueFilterPanelState extends State<VenueFilterPanel> {
  late VenueFilterState _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  // ── Price level labels ──
  static const _priceLevelLabels = <int, String>{
    0: 'Ücretsiz',
    1: '₺',
    2: '₺₺',
    3: '₺₺₺',
    4: '₺₺₺₺',
  };

  // ── Distance options (null = unlimited) ──
  static const _distanceOptions = <double?>[1, 3, 5, 10, 20, null];

  String _distanceLabel(double? km) => km == null ? 'Sınırsız' : '${km.toInt()} km';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          _buildHeader(),
          const Divider(height: 1, color: AppColors.borderLight),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnvironmentSection(),
                  const SizedBox(height: 20),
                  _buildPriceLevelSection(),
                  const SizedBox(height: 20),
                  _buildRatingSection(),
                  const SizedBox(height: 20),
                  _buildDistanceSection(),
                  const SizedBox(height: 20),
                  _buildOnlyOpenSection(),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          _buildBottomActions(),
        ],
      ),
    );
  }

  // ── Drag handle ──
  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // ── Header: title + badge + close ──
  Widget _buildHeader() {
    final count = _filter.activeFilterCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            'Filtreler',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close, size: 24, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ── Environment toggle (İç / Dış mekan) ──
  Widget _buildEnvironmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Mekan Türü'),
        const SizedBox(height: 8),
        Row(
          children: VenueEnvironment.values.map((env) {
            final selected = _filter.environment == env;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _filter = _filter.copyWith(environment: env);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.tagBackground,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.borderLight,
                    ),
                    borderRadius: _segmentBorder(
                      VenueEnvironment.values.indexOf(env),
                      VenueEnvironment.values.length,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _environmentLabel(env),
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static String _environmentLabel(VenueEnvironment env) {
    return switch (env) {
      VenueEnvironment.all => 'Tümü',
      VenueEnvironment.indoor => 'İç Mekan',
      VenueEnvironment.outdoor => 'Dış Mekan',
    };
  }

  /// Rounded corners for segmented control edges.
  BorderRadius _segmentBorder(int index, int total) {
    const r = Radius.circular(8);
    if (index == 0) return const BorderRadius.horizontal(left: r);
    if (index == total - 1) return const BorderRadius.horizontal(right: r);
    return BorderRadius.zero;
  }

  // ── Price level chips (multi-select) ──
  Widget _buildPriceLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Fiyat Seviyesi'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _priceLevelLabels.entries.map((e) {
            final selected = _filter.priceLevels.contains(e.key);
            return GestureDetector(
              onTap: () {
                final updated = Set<int>.from(_filter.priceLevels);
                selected ? updated.remove(e.key) : updated.add(e.key);
                setState(() {
                  _filter = _filter.copyWith(priceLevels: updated);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.tagBackground,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e.value,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Minimum rating slider ──
  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('Minimum Puan'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _filter.minRating > 0
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.tagBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    _filter.minRating.toStringAsFixed(1),
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.borderLight,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _filter.minRating,
            min: 0.0,
            max: 5.0,
            divisions: 10,
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(minRating: value);
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: GoogleFonts.lexend(fontSize: 11, color: AppColors.textLight)),
              Text('5', style: GoogleFonts.lexend(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Maximum distance chips (single-select, null = unlimited) ──
  Widget _buildDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Maksimum Mesafe'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _distanceOptions.map((km) {
            final selected = _filter.maxDistanceKm == km;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _filter = _filter.copyWith(maxDistanceKm: () => km);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.tagBackground,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _distanceLabel(km),
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── "Şu An Açık" switch ──
  Widget _buildOnlyOpenSection() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Şu An Açık',
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
        Switch.adaptive(
          value: _filter.onlyOpen,
          activeTrackColor: AppColors.primary,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(onlyOpen: value);
            });
          },
        ),
      ],
    );
  }

  // ── Bottom action bar: Clear + Apply ──
  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filter = VenueFilterState.empty;
                });
              },
              child: Text(
                'Filtreleri Temizle',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.onFilterChanged(_filter);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Uygula',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared section label ──
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.lexend(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
    );
  }
}
