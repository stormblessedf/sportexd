import 'package:flutter/material.dart';
import '../../../../core/models/formation_config.dart';

/// Widget for selecting match format and formation in football meetups
class FormationPickerWidget extends StatelessWidget {
  final String selectedFormat;
  final String selectedFormation;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onFormationChanged;

  const FormationPickerWidget({
    super.key,
    required this.selectedFormat,
    required this.selectedFormation,
    required this.onFormatChanged,
    required this.onFormationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Takım Dizilişi',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Format selector (horizontal chips)
        _buildFormatSelector(context, colorScheme),
        const SizedBox(height: 16),

        // Formation options
        _buildFormationOptions(context, colorScheme),
      ],
    );
  }

  Widget _buildFormatSelector(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FormationData.formats.map((format) {
          final isSelected = format == selectedFormat;
          final playersPerTeam = FormationData.playersPerTeam(format);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(format),
              selected: isSelected,
              onSelected: (_) => onFormatChanged(format),
              avatar: isSelected
                  ? null
                  : CircleAvatar(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      child: Text(
                        '$playersPerTeam',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
              selectedColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormationOptions(BuildContext context, ColorScheme colorScheme) {
    final formations = FormationData.formations[selectedFormat] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diziliş Seçin',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: formations.map((config) {
              final isSelected = config.formation == selectedFormation;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _FormationCard(
                  config: config,
                  isSelected: isSelected,
                  onTap: () => onFormationChanged(config.formation),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _FormationCard extends StatelessWidget {
  final FormationConfig config;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormationCard({
    required this.config,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Formation name
            Text(
              config.formation,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Position breakdown
            _buildPositionBreakdown(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionBreakdown(
      BuildContext context, ColorScheme colorScheme) {
    final positions = [
      FootballPosition.goalkeeper,
      FootballPosition.defender,
      FootballPosition.midfielder,
      FootballPosition.forward,
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: positions.map((position) {
        final count = config.positionCounts[position] ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return _PositionBadge(
          position: position,
          count: count,
          isSelected: isSelected,
        );
      }).toList(),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final FootballPosition position;
  final int count;
  final bool isSelected;

  const _PositionBadge({
    required this.position,
    required this.count,
    required this.isSelected,
  });

  Color _getPositionColor(ColorScheme colorScheme) {
    switch (position) {
      case FootballPosition.goalkeeper:
        return Colors.orange;
      case FootballPosition.defender:
        return Colors.blue;
      case FootballPosition.midfielder:
        return Colors.green;
      case FootballPosition.forward:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final positionColor = _getPositionColor(colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: positionColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: positionColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            position.shortName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: positionColor,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              color: positionColor,
            ),
          ),
        ],
      ),
    );
  }
}
