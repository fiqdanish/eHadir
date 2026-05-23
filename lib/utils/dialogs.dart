import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../theme.dart';

Future<void> showLogoutConfirmation(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: EHadirTheme.card,
      title: const Text('Log Keluar', style: TextStyle(color: EHadirTheme.textPrimary)),
      content: const Text('Adakah anda pasti mahu log keluar?', style: TextStyle(color: EHadirTheme.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal', style: TextStyle(color: EHadirTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: EHadirTheme.rejected),
          child: const Text('Log Keluar'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    ref.read(authProvider).signOut();
  }
}
