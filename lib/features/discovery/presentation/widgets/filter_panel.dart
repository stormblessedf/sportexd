import 'package:flutter/material.dart';
import '../../../../core/models/filter_state.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../theme/app_theme.dart';

class FilterPanel extends StatefulWidget {
  final FilterState initialState;
  final bool hasLocationPermission;
  final ValueChanged<FilterState> onApply;
  final VoidCallback onClear;
  final VoidCallback onRequestLocation;

  const FilterPanel({
    super.key,
    required this.initialState,
    required this.hasLocationPermission,
    required this.onApply,
    required this.onClear,
    required this.onRequestLocation,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late FilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtreler',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                ),
                if (_state.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _state = FilterState.empty;
                      });
                    },
                    child: const Text(
                      'Temizle',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sport Types
                  _buildSectionTitle('Spor Türü'),
                  const SizedBox(height: 12),
                  _buildSportTypeChips(),
                  const SizedBox(height: 24),

                  // Date Range
                  _buildSectionTitle('Tarih'),
                  const SizedBox(height: 12),
                  _buildDateRangeSelector(),
                  const SizedBox(height: 24),

                  // Distance
                  _buildSectionTitle('Mesafe'),
                  const SizedBox(height: 12),
                  _buildDistanceSelector(),
                  const SizedBox(height: 24),

                  // Participant Availability
                  _buildSectionTitle('Katılımcı Durumu'),
                  const SizedBox(height: 12),
                  _buildParticipantSelector(),
                  const SizedBox(height: 24),

                  // Sort Order
                  _buildSectionTitle('Sıralama'),
                  const SizedBox(height: 12),
                  _buildSortSelector(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_state);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Uygula${_state.activeFilterCount > 0 ? ' (${_state.activeFilterCount})' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildSportTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MeetupType.values.map((type) {
        final isSelected = _state.sportTypes.contains(type);
        return FilterChip(
          selected: isSelected,
          label: Text(type.displayName),
          avatar: Icon(
            _getSportIcon(type),
            size: 18,
            color: isSelected ? AppTheme.primary : AppTheme.textMuted,
          ),
          selectedColor: AppTheme.primary.withValues(alpha:0.15),
          checkmarkColor: AppTheme.primary,
          side: BorderSide(
            color: isSelected
                ? AppTheme.primary.withValues(alpha:0.3)
                : AppTheme.borderLight,
          ),
          onSelected: (selected) {
            setState(() {
              final types = Set<MeetupType>.from(_state.sportTypes);
              if (selected) {
                types.add(type);
              } else {
                types.remove(type);
              }
              _state = _state.copyWith(sportTypes: types);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildDateChip('Tümü', DateRangeType.all),
        _buildDateChip('Bugün', DateRangeType.today),
        _buildDateChip('Bu Hafta', DateRangeType.thisWeek),
        _buildDateChip('Bu Ay', DateRangeType.thisMonth),
      ],
    );
  }

  Widget _buildDateChip(String label, DateRangeType type) {
    final isSelected = _state.dateRange.type == type;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppTheme.primary.withValues(alpha:0.15),
      side: BorderSide(
        color: isSelected
            ? AppTheme.primary.withValues(alpha:0.3)
            : AppTheme.borderLight,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _state = _state.copyWith(
              dateRange: DateRangeFilter(type: type),
            );
          });
        }
      },
    );
  }

  Widget _buildDistanceSelector() {
    if (!widget.hasLocationPermission) {
      return InkWell(
        onTap: widget.onRequestLocation,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha:0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konum izni gerekli',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'Mesafe filtresini kullanmak için izin verin',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.orange),
            ],
          ),
        ),
      );
    }

    final distances = [
      (null, 'Tümü'),
      (5.0, '5 km'),
      (10.0, '10 km'),
      (25.0, '25 km'),
      (50.0, '50 km'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: distances.map((d) {
        final isSelected = _state.distance?.radiusKm == d.$1 ||
            (d.$1 == null && _state.distance == null);
        return ChoiceChip(
          selected: isSelected,
          label: Text(d.$2),
          avatar: d.$1 == null
              ? null
              : const Icon(Icons.near_me, size: 16),
          selectedColor: AppTheme.primary.withValues(alpha:0.15),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primary.withValues(alpha:0.3)
                : AppTheme.borderLight,
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() {
                if (d.$1 == null) {
                  _state = _state.copyWith(clearDistance: true);
                } else {
                  _state = _state.copyWith(
                    distance: DistanceFilter(
                      radiusKm: d.$1!,
                      userLatitude: 0, // Will be set by controller
                      userLongitude: 0,
                    ),
                  );
                }
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildParticipantSelector() {
    final options = [
      (ParticipantFilter.any, 'Tümü', Icons.groups),
      (ParticipantFilter.hasSpace, 'Yer Var', Icons.check_circle_outline),
      (ParticipantFilter.almostFull, 'Dolmak Üzere', Icons.hourglass_bottom),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = _state.participantFilter == o.$1;
        return ChoiceChip(
          selected: isSelected,
          label: Text(o.$2),
          avatar: Icon(o.$3, size: 18),
          selectedColor: AppTheme.primary.withValues(alpha:0.15),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primary.withValues(alpha:0.3)
                : AppTheme.borderLight,
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _state = _state.copyWith(participantFilter: o.$1);
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortSelector() {
    final options = [
      (SortOrder.intelligent, 'Akıllı', Icons.auto_awesome),
      (SortOrder.date, 'Tarih', Icons.calendar_today),
      (SortOrder.distance, 'Mesafe', Icons.near_me),
      (SortOrder.popularity, 'Popülerlik', Icons.trending_up),
      (SortOrder.newest, 'En Yeni', Icons.new_releases),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = _state.sortOrder == o.$1;
        return ChoiceChip(
          selected: isSelected,
          label: Text(o.$2),
          avatar: Icon(o.$3, size: 18),
          selectedColor: AppTheme.primary.withValues(alpha:0.15),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primary.withValues(alpha:0.3)
                : AppTheme.borderLight,
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _state = _state.copyWith(sortOrder: o.$1);
              });
            }
          },
        );
      }).toList(),
    );
  }

  IconData _getSportIcon(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return Icons.sports_soccer;
      case MeetupType.basketball:
        return Icons.sports_basketball;
      case MeetupType.volleyball:
        return Icons.sports_volleyball;
      case MeetupType.tennis:
        return Icons.sports_tennis;
      case MeetupType.tableTennis:
        return Icons.sports_cricket;
      case MeetupType.badminton:
        return Icons.sports_tennis;
      case MeetupType.swimming:
        return Icons.pool;
      case MeetupType.running:
        return Icons.directions_run;
      case MeetupType.cycling:
        return Icons.directions_bike;
      case MeetupType.hiking:
        return Icons.hiking;
      case MeetupType.yoga:
        return Icons.self_improvement;
      case MeetupType.fitness:
        return Icons.fitness_center;
      case MeetupType.boxing:
        return Icons.sports_mma;
      case MeetupType.climbing:
        return Icons.terrain;
      case MeetupType.skiing:
        return Icons.downhill_skiing;
      case MeetupType.other:
        return Icons.sports;
    }
  }
}
