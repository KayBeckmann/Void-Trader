import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 64, color: AppColors.outline),
            const SizedBox(height: 16),
            Text(
              'FORSCHUNG & ENTWICKLUNG',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.1,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'M4 — Tech-Baum ausstehend',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
