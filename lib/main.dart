import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const VozApp());
}

class VozApp extends StatelessWidget {
  const VozApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voz',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
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
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            // Bottom nav overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomNav(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.bg,
            AppColors.bg,
            AppColors.bg.withOpacity(0),
          ],
          stops: const [0, 0.7, 1],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(40, 12, 40, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: '◉',
            label: 'hoy',
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: '▤',
            label: 'historial',
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: active ? 1.0 : 0.35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                icon,
                style: TextStyle(
                  fontSize: 20,
                  color: active ? AppColors.accent : AppColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.dmMono(
                  fontSize: 9,
                  letterSpacing: 0.08,
                  color: active ? AppColors.accent : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
