import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/domain/ship_stats.dart';
import '../../../shared/theme/app_colors.dart';

class HudOverlay extends StatelessWidget {
  final ShipStats stats;
  final String systemName;
  final double credits;

  const HudOverlay({
    super.key,
    required this.stats,
    required this.systemName,
    required this.credits,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HudHeader(
            systemName: systemName,
            shieldPercent: stats.shieldPercent,
            hullPercent: stats.hullPercent,
            credits: credits,
          ),
        ],
      ),
    );
  }
}

class _HudHeader extends StatelessWidget {
  final String systemName;
  final double shieldPercent;
  final double hullPercent;
  final double credits;

  const _HudHeader({
    required this.systemName,
    required this.shieldPercent,
    required this.hullPercent,
    required this.credits,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.80),
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 6,
            12,
            8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // System name
              _SystemName(name: systemName),

              const Spacer(),

              // Shield + Hull bars
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SegmentedBar(
                    label: 'SHD',
                    percent: shieldPercent,
                    color: AppColors.shieldColor,
                  ),
                  const SizedBox(height: 4),
                  _SegmentedBar(
                    label: 'HUL',
                    percent: hullPercent,
                    color: _hullColor(hullPercent),
                  ),
                ],
              ),

              const Spacer(),

              // Credits + Settings
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.toll_outlined,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _fmtCredits(credits),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 8),
                  _SettingsButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hullColor(double pct) {
    if (pct > 0.50) return AppColors.hullColor;
    if (pct > 0.25) return AppColors.secondary;
    return AppColors.error;
  }

  String _fmtCredits(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _SystemName extends StatelessWidget {
  final String name;
  const _SystemName({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.rocket_launch, color: AppColors.primary, size: 18),
        const SizedBox(width: 6),
        Text(
          name.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryFixed,
                fontSize: 18,
                letterSpacing: 0.08,
                shadows: [
                  Shadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.60),
                    blurRadius: 8,
                  ),
                ],
              ),
        ),
      ],
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const _SegmentedBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  static const _segments = 10;

  @override
  Widget build(BuildContext context) {
    final filled = (percent.clamp(0.0, 1.0) * _segments).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  letterSpacing: 0.12,
                ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          height: 8,
          width: 128,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineVariant, width: 1),
          ),
          padding: const EdgeInsets.all(1),
          child: Row(
            children: List.generate(_segments, (i) {
              final active = i < filled;
              return Expanded(
                child: Container(
                  margin: i < _segments - 1
                      ? const EdgeInsets.only(right: 1)
                      : EdgeInsets.zero,
                  color: active ? color : color.withValues(alpha: 0.15),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Icon(
        Icons.settings_outlined,
        size: 16,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}
