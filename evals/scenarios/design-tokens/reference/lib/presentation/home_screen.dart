import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredBox(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Offline mode',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Eval App', style: textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
