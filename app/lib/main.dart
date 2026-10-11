import 'package:flutter/material.dart';

import 'app_state.dart';
import 'notify.dart';
import 'ui/calendar_page.dart';
import 'ui/scriptures_page.dart';
import 'ui/settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DaoLiApp());
}

class DaoLiApp extends StatelessWidget {
  const DaoLiApp({super.key});

  static const paper = Color(0xFFF7F4EC); // 宣纸
  static const ink = Color(0xFF33302A); // 墨
  static const accent = Color(0xFF93483E); // 朱砂
  static const line = Color(0xFFE2DCCB);
  static const muted = Color(0xFF8A857A);

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: paper,
    );
    return MaterialApp(
      title: '道历',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: line),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        dividerTheme: const DividerThemeData(color: line, thickness: 1),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final AppState state = AppState();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    state.init().then((_) async {
      await initNotifications();
      await rescheduleReminders(state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        if (state.engine == null) {
          return const Scaffold(
            body: Center(child: Text('道历载入中…', style: TextStyle(fontSize: 16))),
          );
        }
        final pages = [
          CalendarPage(state: state),
          ScripturesPage(state: state),
          SettingsPage(state: state),
        ];
        return Scaffold(
          // IndexedStack 保活三个页签：切换后日历的选中日期/月份不重置
          body: IndexedStack(index: _tab, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFF0E4D8),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: '日历'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '经典'),
              NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: '提醒'),
            ],
          ),
        );
      },
    );
  }
}
