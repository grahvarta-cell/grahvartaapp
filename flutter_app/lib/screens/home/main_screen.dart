import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/home/home_cubit.dart';
import '../../blocs/marketplace/marketplace_cubit.dart';
import '../../blocs/reports/reports_cubit.dart';
import '../../blocs/live/live_cubit.dart';
import '../../theme/app_theme.dart';
import 'home_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../live/live_screen.dart';
import '../kundli/kundli_screen.dart';
import '../reports/reports_screen.dart';

// Global notifier to switch tabs from anywhere
final mainTabNotifier = ValueNotifier<int>(0);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  // Lazy loading: only build a screen when first visited
  final Set<int> _visited = {0};

  static const _screens = [
    HomeScreen(),
    MarketplaceScreen(),
    ReportsScreen(),
    LiveScreen(),
    KundliScreen(),
  ];

  @override
  void initState() {
    super.initState();
    mainTabNotifier.addListener(_onTabChange);
  }

  @override
  void dispose() {
    mainTabNotifier.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() {
    final i = mainTabNotifier.value;
    setState(() { _visited.add(i); _currentIndex = i; });
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    // Show exit confirmation
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.clr.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Exit App', style: TextStyle(color: context.clr.txtPrimary)),
        content: Text('Are you sure you want to exit?', style: TextStyle(color: context.clr.txtSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: context.clr.txtSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeCubit()),
        BlocProvider(create: (_) => MarketplaceCubit()),
        BlocProvider(create: (_) => ReportsCubit()),
        BlocProvider(create: (_) => LiveCubit()),
      ],
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: List.generate(_screens.length, (i) =>
              _visited.contains(i) ? _screens[i] : const SizedBox.shrink(),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: context.clr.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(icon: Icons.home_rounded, index: 0, label: 'Home'),
              _navItem(icon: Icons.people_rounded, index: 1, label: 'Astrologers'),
              _navItem(icon: Icons.auto_awesome, index: 2, label: 'Reports'),
              _navItem(icon: Icons.live_tv_rounded, index: 3, label: 'Live', badge: '2'),
              _navItem(icon: Icons.auto_awesome, index: 4, label: 'Kundli'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required int index, required String label, String? badge}) {
    final isSelected = index == _currentIndex;
    Widget iconWidget = Icon(icon, color: isSelected ? Colors.white : context.clr.txtMuted, size: 22);

    if (badge != null && !isSelected) {
      iconWidget = badges.Badge(
        badgeContent: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8)),
        badgeStyle: badges.BadgeStyle(badgeColor: context.clr.error),
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: () => setState(() { _visited.add(index); _currentIndex = index; mainTabNotifier.value = index; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.clr.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          iconWidget,
          if (isSelected) ...[
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }
}
