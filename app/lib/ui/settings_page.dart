import 'package:flutter/material.dart';

import '../app_state.dart';

import '../models.dart';

import '../theme.dart';

class SettingsPage extends StatefulWidget {
  final AppState state;
  const SettingsPage({super.key, required this.state});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text('提醒',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),

          // 总开关 + 时间
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('启用提醒',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(s.remindersEnabled
                      ? '按下方分类每日排期未来一年'
                      : '已关闭，不排期任何提醒'),
                  value: s.remindersEnabled,
                  activeThumbColor: T.accent,
                  onChanged: (v) async {
                    setState(() => s.remindersEnabled = v);
                    await s.applyAndReschedule();
                    _toast(v ? '已重新排期提醒' : '已取消全部提醒');
                  },
                ),
                ListTile(
                  enabled: s.remindersEnabled,
                  title: const Text('提醒时间'),
                  subtitle: Text('每日 ${s.reminderTime}'),
                  trailing: const Icon(Icons.access_time, color: T.muted),
                  onTap: s.remindersEnabled
                      ? () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _parse(s.reminderTime),
                          );
                          if (t != null) {
                            setState(() => s.reminderTime =
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                            await s.applyAndReschedule();
                            _toast('提醒时间已更新');
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),

          // 分类
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 16, 6),
            child: Text('提醒分类', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Card(
            child: Column(
              children: ReminderGroups.all
                  .map((g) => SwitchListTile(
                        title: Text(g.label),
                        subtitle: Text(g.desc,
                            style: const TextStyle(fontSize: 12)),
                        value: s.groupOn[g.id] ?? g.defaultOn,
                        activeThumbColor: T.accent,
                        onChanged: s.remindersEnabled
                            ? (v) async {
                                setState(() => s.groupOn[g.id] = v);
                                await s.applyAndReschedule();
                              }
                            : null,
                      ))
                  .toList(),
            ),
          ),

          // 预览
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 16, 6),
            child: Text('近期提醒预览', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Card(
            child: _Preview(state: s),
          ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '经典日期属传统文化辑录，各道派仪范或有差异，请以所属传承为准。',
              style: TextStyle(fontSize: 12, color: T.muted, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  TimeOfDay _parse(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.tryParse(p[1]) ?? 0);
  }
}

class _Preview extends StatelessWidget {
  final AppState state;
  const _Preview({required this.state});

  @override
  Widget build(BuildContext context) {
    final engine = state.engine;
    if (engine == null) return const SizedBox(height: 40);
    final items = <String>[];
    var cur = DateTime.now();
    for (var i = 0; i < 60 && items.length < 5; i++) {
      final d = cur.add(Duration(days: i));
      final info = engine.dayInfo(d);
      final evs = info.events.where(state.shouldRemind).toList();
      if (evs.isEmpty) continue;
      final lunarText =
          '${info.lunar.getMonthInChinese()}月${info.lunar.getDayInChinese()}';
      items.add('${d.month}月${d.day}日（$lunarText）— ${evs.take(3).map((e) => e.name).join('、')}${evs.length > 3 ? ' 等' : ''}');
    }
    if (items.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(16), child: Text('未来两个月暂无所选分类的提醒。'));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(t, style: const TextStyle(fontSize: 13, height: 1.4)),
                ))
            .toList(),
      ),
    );
  }
}
