import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'routing/app_router.dart';

class PosApp extends ConsumerStatefulWidget {
  const PosApp({required this.refreshListenable, super.key});

  final ValueNotifier<int> refreshListenable;

  @override
  ConsumerState<PosApp> createState() => _PosAppState();
}

class _PosAppState extends ConsumerState<PosApp> {
  late final GoRouter _router = buildAppRouter(
    ref: ref,
    refreshListenable: widget.refreshListenable,
  );

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    ref.listen<AuthState>(authControllerProvider, (_, _) {
      widget.refreshListenable.value++;
    });
    return MaterialApp.router(
      title: 'Bagimu Negriku Market (BN Mart)',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
