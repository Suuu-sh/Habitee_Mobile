import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/category_select_screen.dart';
import 'screens/insight_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(const HabiteeApp());
}

class HabiteeApp extends StatelessWidget {
  const HabiteeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'habitee',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _refreshToken = 0;
  final ValueNotifier<int> _historyTick = ValueNotifier<int>(0);

  Future<void> _openAddTask() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => const CategorySelectScreen(),
    );
    setState(() {
      _refreshToken += 1;
    });
  }

  void _notifyHistoryUpdate() {
    _historyTick.value += 1;
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            refreshToken: _refreshToken,
            onFailureRecorded: _notifyHistoryUpdate,
          ),
          const InsightScreen(),
          HistoryScreen(refreshListenable: _historyTick),
          const _PlaceholderScreen(label: 'Settings', emoji: '⚙️'),
        ],
      ),
      floatingActionButton: null,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Container(
          height: 72,
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: _selectedIndex == 0,
                activeColor: colorScheme.primary,
                onTap: () => _onTabSelected(0),
              ),
              _NavItem(
                icon: Icons.insights_rounded,
                label: 'Insight',
                active: _selectedIndex == 1,
                activeColor: colorScheme.primary,
                onTap: () => _onTabSelected(1),
              ),
              _AddTabButton(
                onTap: _openAddTask,
                primary: colorScheme.primary,
                secondary: colorScheme.secondary,
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                active: _selectedIndex == 2,
                activeColor: colorScheme.primary,
                onTap: () => _onTabSelected(2),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                active: _selectedIndex == 3,
                activeColor: colorScheme.primary,
                onTap: () => _onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : Colors.grey[400];
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: active ? activeColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(height: 1),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textScaler: const TextScaler.linear(1.0),
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTabButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color primary;
  final Color secondary;

  const _AddTabButton({
    required this.onTap,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary, secondary]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 2),
              const Text(
                'Add',
                textScaler: TextScaler.linear(1.0),
                style: TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  final String emoji;

  const _PlaceholderScreen({required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '近日公開',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
