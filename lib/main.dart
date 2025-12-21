import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/category_select_screen.dart';

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
        primarySwatch: Colors.green,
        useMaterial3: true,
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

  Future<void> _openAddTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategorySelectScreen()),
    );
    setState(() {
      _refreshToken += 1;
    });
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(refreshToken: _refreshToken),
          const _PlaceholderScreen(label: 'Insight'),
          const _PlaceholderScreen(label: 'History'),
          const _PlaceholderScreen(label: 'Settings'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTask,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
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
              const SizedBox(width: 56),
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
    final color = active ? activeColor : Colors.grey[500];
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String label;

  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
