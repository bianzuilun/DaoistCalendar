import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'notify.dart';
import 'rules_engine.dart';

/// 经典条目
class Scripture {
  final String id;
  final String title;
  final String common;
  final String deity;
  final String desc;
  final List<Map<String, dynamic>> dates; // label/type/m/d/d1/d2/term/days
  final List<Map<String, String>>? benming;

  Scripture({
    required this.id,
    required this.title,
    required this.common,
    required this.deity,
    required this.desc,
    required this.dates,
    this.benming,
  });

  static Scripture fromJson(Map<String, dynamic> j) => Scripture(
        id: j['id'] as String,
        title: j['title'] as String,
        common: j['common'] as String? ?? '',
        deity: j['deity'] as String? ?? '',
        desc: j['desc'] as String? ?? '',
        dates: (j['dates'] as List? ?? []).cast<Map<String, dynamic>>(),
        benming: (j['benming'] as List?)
            ?.map((e) => (e as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, v as String)))
            .toList(),
      );
}

/// 全局状态：引擎、设置、提醒排期
class AppState extends ChangeNotifier {
  RulesEngine? engine;
  List<Scripture> scriptures = [];

  bool remindersEnabled = true;
  String reminderTime = '07:00';
  Map<String, bool> groupOn = {
    for (final g in ReminderGroups.all) g.id: g.defaultOn,
  };

  Future<void> init() async {
    engine = await RulesEngine.loadFromAssets();
    final raw = await rootBundle.loadString('assets/data/scriptures.json');
    final list = (json.decode(raw) as Map<String, dynamic>)['scriptures'] as List;
    scriptures = list.map((e) => Scripture.fromJson(e as Map<String, dynamic>)).toList();
    final prefs = await SharedPreferences.getInstance();
    remindersEnabled = prefs.getBool('remindersEnabled') ?? true;
    reminderTime = prefs.getString('reminderTime') ?? '07:00';
    for (final g in ReminderGroups.all) {
      groupOn[g.id] = prefs.getBool('group_${g.id}') ?? g.defaultOn;
    }
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindersEnabled', remindersEnabled);
    await prefs.setString('reminderTime', reminderTime);
    for (final e in groupOn.entries) {
      await prefs.setBool('group_${e.key}', e.value);
    }
  }

  /// 设置变更后持久化并重新排期提醒
  Future<void> applyAndReschedule() async {
    await saveSettings();
    notifyListeners();
    await rescheduleReminders(this);
  }

  /// 某事件是否属于已开启的提醒分组
  bool shouldRemind(DaoEvent e) {
    final g = groupOf(e);
    return groupOn[g.id] ?? false;
  }
}
