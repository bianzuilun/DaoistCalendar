import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'notify.dart';
import 'theme.dart';
import 'ui/calendar_page.dart';
import 'ui/scriptures_page.dart';
import 'ui/settings_page.dart';
import 'ui/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DaoLiApp());
}

class DaoLiApp extends StatelessWidget {
  const DaoLiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '道历',
      debugShowCheckedModeBanner: false,
      theme: daoTheme(),
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: T.card,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SealMark('道', size: 56),
                  SizedBox(height: 16),
                  Text('道历载入中', style: T.bodyMuted),
                ],
              ),
            ),
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
          bottomNavigationBar: DaoNavBar(
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        );
      },
    );
  }
}
