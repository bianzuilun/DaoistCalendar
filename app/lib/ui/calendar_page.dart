import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

import '../app_state.dart';

import '../models.dart';
import '../rules_engine.dart';
import '../theme.dart';

class CalendarPage extends StatefulWidget {
  final AppState state;
  const CalendarPage({super.key, required this.state});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  void _shift(int months) {
    setState(() {
      _month = DateTime(_month.year, _month.month + months);
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.state.engine!;
    final today = DateTime.now();
    final todayInfo = engine.dayInfo(today);
    const ink = T.ink;
    const muted = T.muted;
    

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ===== 今日卡 =====
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: T.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${today.month}月${today.day}日',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w700, color: ink)),
                    const SizedBox(height: 4),
                    Text(
                      '${todayInfo.lunar.getYearInGanZhi()}年 '
                      '${todayInfo.lunar.getMonthInChinese()}月${todayInfo.lunar.getDayInChinese()}'
                      '${todayInfo.jieQi.isEmpty ? '' : ' · ${todayInfo.jieQi}'}',
                      style: TextStyle(fontSize: 14, color: muted),
                    ),
                    Text('道历${daoYearCN(today.year)}年 · 属${todayInfo.lunar.getYearShengXiao()}',
                        style: TextStyle(fontSize: 14, color: muted)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF3EA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE8D5C4)),
                  ),
                  child: Text('道历\n${daoYearCN(today.year)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, height: 1.4, color: T.accent,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (todayInfo.events.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: todayInfo.events.take(4)
                    .map((e) => EventChip(event: e, compact: true)).toList(),
              ),
            ),

          // ===== 月份导航 =====
          Builder(builder: (context) {
            final now = DateTime.now();
            final away = _month.year != now.year ||
                _month.month != now.month ||
                _selected != DateTime(now.year, now.month, now.day);
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
                  Text('${_month.year}年${_month.month}月',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ink)),
                  const Spacer(),
                  if (away)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: _goToday,
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: T.accent, width: 1.2),
                          ),
                          child: const Text('今',
                              style: TextStyle(
                                  fontSize: 16,
                                  height: 1,
                                  color: T.accent,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right)),
                ],
              ),
            );
          }),

          // ===== 月历格 =====
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: T.line),
            ),
            padding: const EdgeInsets.all(8),
            child: _MonthGrid(
              month: _month,
              engine: engine,
              selected: _selected,
              today: DateTime(today.year, today.month, today.day),
              onSelect: (d) => setState(() => _selected = d),
            ),
          ),

          // ===== 选中日详情 =====
          _DayDetail(engine: engine, date: _selected),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final RulesEngine engine;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.month,
    required this.engine,
    required this.selected,
    required this.today,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const weekLabels = ['一', '二', '三', '四', '五', '六', '日'];
    final first = DateTime(month.year, month.month);
    final startOffset = (first.weekday + 6) % 7; // 周一为始
    final gridStart = first.subtract(Duration(days: startOffset));

    return Column(
      children: [
        Row(
          children: weekLabels
              .map((w) => Expanded(
                    child: Center(
                        child: Text(w,
                            style: TextStyle(
                                fontSize: 12,
                                color: (w == '六' || w == '日')
                                    ? T.accent
                                    : T.muted))),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        ...List.generate(6, (r) {
          return Row(
            children: List.generate(7, (c) {
              final date = gridStart.add(Duration(days: r * 7 + c));
              final inMonth = date.month == month.month;
              return Expanded(
                child: _DayCell(
                  date: date,
                  engine: engine,
                  inMonth: inMonth,
                  isToday: date == today,
                  isSelected: date == selected,
                  onTap: () => onSelect(date),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final RulesEngine engine;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.engine,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lunar = Solar.fromYmd(date.year, date.month, date.day).getLunar();
    final events = engine.eventsFor(lunar);
    final isLeap = lunar.getMonth() < 0;
    String lunarText;
    if (lunar.getDay() == 1) {
      lunarText = '${isLeap ? '闰' : ''}${lunar.getMonthInChinese()}月';
    } else {
      lunarText = lunar.getDayInChinese();
    }

    final baseColor = inMonth ? T.ink : const Color(0xFFC9C4B8);
    final isWu = events.any((e) => e.category == '斋戒');

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.78,
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF3E7E0)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: T.accent, width: 1.4)
                : Border.all(color: Colors.transparent),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: baseColor)),
              Text(lunarText,
                  style: TextStyle(
                      fontSize: 10,
                      color: lunar.getDay() == 1
                          ? T.accent
                          : (isWu ? const Color(0xFF8A5A2B) : baseColor))),
              const SizedBox(height: 2),
              SizedBox(
                height: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.take(3).map((e) {
                    final c = categoryColors[e.category] ?? 0xFF8A857A;
                    return Container(
                      width: 4, height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                          color: Color(c), shape: BoxShape.circle),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  final RulesEngine engine;
  final DateTime date;

  const _DayDetail({required this.engine, required this.date});

  @override
  Widget build(BuildContext context) {
    final info = engine.dayInfo(date);
    final lunar = info.lunar;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: T.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${date.month}月${date.day}日',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: T.ink)),
              const SizedBox(width: 8),
              Text('星期${'一二三四五六日'[date.weekday - 1]}', style: const TextStyle(color: T.muted)),
              const Spacer(),
              if (info.jieQi.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0EE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(info.jieQi,
                      style: TextStyle(fontSize: 12, color: const Color(0xFF52796F),
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '农历${lunar.getMonth() < 0 ? '闰' : ''}${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}　'
            '${lunar.getYearInGanZhi()}年 ${lunar.getMonthInGanZhi()}月 ${lunar.getDayInGanZhi()}日　'
            '道历${daoYearCN(date.year)}年',
            style: const TextStyle(fontSize: 13, color: T.muted),
          ),
          const Divider(height: 20),
          if (info.events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('本日无节日记录', style: const TextStyle(color: T.muted)),
            )
          else
            ...info.events.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EventChip(event: e),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.name,
                          style: TextStyle(fontSize: 14, color: T.ink))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class EventChip extends StatelessWidget {
  final DaoEvent event;
  final bool compact;
  const EventChip({super.key, required this.event, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = Color(categoryColors[event.category] ?? 0xFF8A857A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c.withValues(alpha: 0.5), width: 0.7),
      ),
      child: Text(event.category,
          style: TextStyle(fontSize: compact ? 10 : 11, color: c,
              fontWeight: FontWeight.w600)),
    );
  }
}
