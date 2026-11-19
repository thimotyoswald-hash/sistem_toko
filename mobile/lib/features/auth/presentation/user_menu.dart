import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../pos/presentation/store_settings_dialog.dart';
import '../domain/app_user.dart';
import 'auth_controller.dart';

class UserMenu extends ConsumerWidget {
  const UserMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthSignedIn ? auth.user : null;
    if (user == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Menu Akun & Pengaturan',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _roleColor(user.role, scheme).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _roleLabel(user.role),
                            style: TextStyle(
                              fontSize: 10,
                              color: _roleColor(user.role, scheme),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'store_settings',
          child: Row(
            children: [
              Icon(Icons.storefront_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              const Text('Pengaturan Toko & Struk', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: scheme.error),
              const SizedBox(width: 10),
              Text(
                'Keluar Akun',
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'store_settings') {
          showStoreSettingsDialog(context);
        } else if (value == 'logout') {
          ref.read(authControllerProvider.notifier).logout();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CircleAvatar(
          radius: 17,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Color _roleColor(Role role, ColorScheme scheme) {
    switch (role) {
      case Role.kasir:
        return Colors.blue.shade700;
      case Role.admin:
        return Colors.orange.shade800;
      case Role.owner:
        return scheme.primary;
    }
  }

  String _roleLabel(Role role) {
    switch (role) {
      case Role.kasir:
        return 'Petugas Kasir';
      case Role.admin:
        return 'Administrator';
      case Role.owner:
        return 'Pemilik (Owner)';
    }
  }
}
