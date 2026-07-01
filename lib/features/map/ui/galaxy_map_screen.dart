import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class GalaxyMapScreen extends StatelessWidget {
  const GalaxyMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: AppColors.outline),
            const SizedBox(height: 16),
            Text(
              'GALAXIS-KARTE',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.1,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'M2 — Implementierung ausstehend',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
