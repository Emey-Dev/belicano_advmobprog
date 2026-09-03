import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('Dark / Light mode'),
                subtitle: Text(
                  context.watch<ThemeProvider>().isDark
                      ? 'Dark mode'
                      : 'Light mode',
                ),
                secondary: Icon(
                  context.watch<ThemeProvider>().isDark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                value: context.watch<ThemeProvider>().isDark,
                onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
