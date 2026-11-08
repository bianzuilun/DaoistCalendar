import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'widgets.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const PageHeader(
            title: '提醒',
            subtitle: '本地通知，按分类预排未来一年。关掉总开关即全部停止。',
          ),
          PaperCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('每日提醒', style: T.heading),
                          const SizedBox(height: 3),
                          Text(
                            s.remindersEnabled ? '按下方分类排期' : '已关闭，不排期任何提醒',
                            style: T.caption,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: s.remindersEnabled,
                      onChanged: (v) async {
                        setState(() => s.remindersEnabled = v);
                        await s.applyAndReschedule();
                        _toast(v ? '已重新排期提醒' : '已取消全部提醒');
                      },
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Divider(height: 1),
                ),
                InkWell(
                  onTap: s.remindersEnabled ? _pickTime : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Opacity(
                    opacity: s.remindersEnabled ? 1 : 0.4,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('提醒时刻', style: T.caption),
                                const SizedBox(height: 2),
                                Text(
                                  s.reminderTime,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    height: 1.1,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w600,
                                    color: T.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: T.paperDeep,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.schedule, size: 20, color: T.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('提醒分类'),
          PaperCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < ReminderGroups.all.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _GroupRow(
                    group: ReminderGroups.all[i],
                    value: s.groupOn[ReminderGroups.all[i].id] ?? ReminderGroups.all[i].defaultOn,
                    enabled: s.remindersEnabled,
                    onChanged: (v) async {
                      setState(() => s.groupOn[ReminderGroups.all[i].id] = v);
                      await s.applyAndReschedule();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('近期'),
          PaperCard(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: _Preview(state: s),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 16, 4, 0),
            child: Text(
              '经典日期属传统文化辑录，各道派仪范或有差异，请以所属传承为准。',
              style: T.caption,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final s = widget.state;
    final t = await showTimePicker(
      context: context,
      initialTime: _parse(s.reminderTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: T.card,
              hourMinuteColor: T.paperDeep,
              hourMinuteTextColor: T.ink,
              dayPeriodColor: T.paperDeep,
              dayPeriodTextColor: T.ink,
              dialHandColor: T.accent,
              dialBackgroundColor: T.paper,
              entryModeIconColor: T.inkSoft,
            ),
          ),
          child: child!,
        );
      },
    );
    if (t != null) {
      setState(() => s.reminderTime =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
      await s.applyAndReschedule();
      _toast('提醒时间已更新');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  TimeOfDay _parse(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.tryParse(p[1]) ?? 0);
  }
}

class _GroupRow extends StatelessWidget {
  final ReminderGroup group;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _GroupRow({
    required this.group,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = groupColor(group.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(group.desc, style: const TextStyle(fontSize: 12, height: 1.35, color: T.muted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _PreviewItem {
  final DateTime date;
  final String lunar;
  final List<DaoEvent> events;
  final bool isToday;
  const _PreviewItem(this.date, this.lunar, this.events, this.isToday);
}

class _Preview extends StatelessWidget {
  final AppState state;
  const _Preview({required this.state});

  @override
  Widget build(BuildContext context) {
    final engine = state.engine;
    if (engine == null) return const SizedBox(height: 40);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final items = <_PreviewItem>[];
    for (var i = 0; i < 60 && items.length < 5; i++) {
      final d = todayDate.add(Duration(days: i));
      final info = engine.dayInfo(d);
      final evs = info.events.where(state.shouldRemind).toList();
      if (evs.isEmpty) continue;
      items.add(_PreviewItem(
        d,
        '${info.lunar.getMonthInChinese()}月${info.lunar.getDayInChinese()}',
        evs,
        d == todayDate,
      ));
    }
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('未来两个月暂无所选分类的提醒。', style: T.bodyMuted),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${items[i].date.month}月${items[i].date.day}日',
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: items[i].isToday ? T.accent : T.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(items[i].lunar, softWrap: false, style: T.caption),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: categoryColor(items[i].events.first.category),
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      '${items[i].events.take(3).map((e) => e.name).join('、')}${items[i].events.length > 3 ? ' 等' : ''}',
                      style: const TextStyle(fontSize: 13, height: 1.45, color: T.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
