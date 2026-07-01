import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory_outlined, size: 64, color: AppColors.outline),
            const SizedBox(height: 16),
            Text(
              'FLOTTEN-EDITOR',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.1,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'M3 — Block-Logik-Editor ausstehend',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
