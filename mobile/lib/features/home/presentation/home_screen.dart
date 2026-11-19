import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../pos/presentation/pos_screen.dart';
import '../../products/presentation/product_manage_screen.dart';
import '../../purchases/presentation/purchase_screen.dart';
import '../../reports/presentation/profit_loss_screen.dart';
import '../../reports/presentation/stock_history_screen.dart';
import '../../stock/presentation/stock_adjustment_screen.dart';

const List<String> _adminTabs = <String>['products', 'purchases', 'stock'];
const List<String> _ownerTabs = <String>['profit', 'history'];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;
  List<String> _tabs = const <String>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = ref.read(authControllerProvider);
    final user = auth is AuthSignedIn ? auth.user : null;
    if (user == null) return;

    final tabs = user.role == Role.admin ? _adminTabs : _ownerTabs;
    _tabs = tabs;

    final requested = GoRouterState.of(context).uri.queryParameters['tab'];
    final newIndex = requested == null ? 0 : tabs.indexOf(requested);
    if (newIndex >= 0 && newIndex != _index) {
      setState(() => _index = newIndex);
    }
  }

  void _setTab(int index) {
    setState(() => _index = index);
    if (_tabs.isEmpty) return;
    context.go('/home?tab=${_tabs[index]}');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthSignedIn ? auth.user : null;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (user.role) {
      case Role.kasir:
        return const PosScreen();
      case Role.admin:
        return _AdminShell(index: _index, onIndex: _setTab, user: user);
      case Role.owner:
        return _OwnerShell(index: _index, onIndex: _setTab, user: user);
    }
  }
}

class _AdminShell extends StatelessWidget {
  const _AdminShell({required this.index, required this.onIndex, required this.user});

  final int index;
  final ValueChanged<int> onIndex;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    const tabs = <Widget>[
      ProductManageScreen(),
      PurchaseScreen(),
      StockAdjustmentScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Produk',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_checkout_outlined),
            selectedIcon: Icon(Icons.shopping_cart_checkout_rounded),
            label: 'Pembelian',
          ),
          NavigationDestination(
            icon: Icon(Icons.remove_circle_outline),
            selectedIcon: Icon(Icons.remove_circle_rounded),
            label: 'Stok Keluar',
          ),
        ],
      ),
    );
  }
}

class _OwnerShell extends StatelessWidget {
  const _OwnerShell({required this.index, required this.onIndex, required this.user});

  final int index;
  final ValueChanged<int> onIndex;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    const tabs = <Widget>[
      ProfitLossScreen(),
      StockHistoryScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Laba Rugi',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Riwayat Stok',
          ),
        ],
      ),
    );
  }
}
