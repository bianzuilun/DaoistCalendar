import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

import '../app_state.dart';
import '../models.dart';
import '../rules_engine.dart';
import '../theme.dart';
import 'widgets.dart';

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayInfo = engine.dayInfo(today);
    final away = _month.year != today.year ||
        _month.month != today.month ||
        _selected != today;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _TodayMasthead(today: today, info: todayInfo, onTap: _goToday),
          const SizedBox(height: 14),
          PaperCard(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                _MonthBar(
                  month: _month,
                  away: away,
                  onPrev: () => _shift(-1),
                  onNext: () => _shift(1),
                  onToday: _goToday,
                ),
                const SizedBox(height: 10),
                _MonthGrid(
                  month: _month,
                  engine: engine,
                  selected: _selected,
                  today: today,
                  onSelect: (d) => setState(() => _selected = d),
                ),
                const SizedBox(height: 10),
                const _Legend(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DayDetail(engine: engine, date: _selected),
        ],
      ),
    );
  }
}

class _TodayMasthead extends StatelessWidget {
  final DateTime today;
  final DayInfo info;
  final VoidCallback onTap;

  const _TodayMasthead({
    required this.today,
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lunar = info.lunar;
    final leap = lunar.getMonth() < 0 ? '闰' : '';
    final lunarLabel = '$leap${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';

    return PaperCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(height: 3, color: T.accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('今日', style: T.kicker),
                              const SizedBox(width: 8),
                              Text(weekdayCN(today), style: T.caption),
                              if (info.jieQi.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                JieQiTag(info.jieQi),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(lunarLabel, style: T.display),
                          const SizedBox(height: 6),
                          Text('公历 ${today.month}月${today.day}日', style: T.bodyMuted),
                          const SizedBox(height: 2),
                          Text(
                            '${lunar.getYearInGanZhi()}年 · 属${lunar.getYearShengXiao()}',
                            style: T.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    DaoYearSeal(year: today.year),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: Pillar(label: '年柱', value: lunar.getYearInGanZhi())),
                    const SizedBox(width: 8),
                    Expanded(child: Pillar(label: '月柱', value: lunar.getMonthInGanZhi())),
                    const SizedBox(width: 8),
                    Expanded(child: Pillar(label: '日柱', value: lunar.getDayInGanZhi())),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  final DateTime month;
  final bool away;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _MonthBar({
    required this.month,
    required this.away,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RoundIconButton(icon: Icons.chevron_left, onTap: onPrev),
        Expanded(
          child: Text(
            '${month.year}年${month.month}月',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: T.ink,
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (away) ...[
          _TodayButton(onTap: onToday),
          const SizedBox(width: 8),
        ],
        RoundIconButton(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _TodayButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TodayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: T.accent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              '今',
              style: TextStyle(
                fontSize: 14,
                height: 1,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  static const _items = [
    ('神诞', '神诞'),
    ('下降', '下降'),
    ('节会', '节会'),
    ('斋戒', '斋戒'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: categoryColor(_items[i].$2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(_items[i].$1, style: const TextStyle(fontSize: 11, color: T.muted)),
        ],
      ],
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
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: T.line, width: 0.6)),
          ),
          child: Row(
            children: weekLabels
                .map((w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: (w == '六' || w == '日') ? T.accent : T.muted,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
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
    final jieQi = lunar.getJieQi();
    final String lunarText;
    if (lunar.getDay() == 1) {
      lunarText = '${isLeap ? '闰' : ''}${lunar.getMonthInChinese()}月';
    } else if (jieQi.isNotEmpty) {
      lunarText = jieQi;
    } else {
      lunarText = lunar.getDayInChinese();
    }
    final isWu = events.any((e) => e.category == '斋戒');

    final Color subColor;
    if (!inMonth) {
      subColor = const Color(0xFFD2C9BB);
    } else if (lunar.getDay() == 1) {
      subColor = T.accent;
    } else if (jieQi.isNotEmpty) {
      subColor = T.jieqi;
    } else if (isWu) {
      subColor = const Color(0xFF8A5A2B);
    } else {
      subColor = T.inkSoft;
    }

    final numberColor = !inMonth
        ? const Color(0xFFC9C0B2)
        : (isSelected || isToday)
            ? T.accent
            : T.ink;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? T.accent.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? T.accent : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 15,
                height: 1.05,
                fontWeight: (isToday || isSelected) ? FontWeight.w700 : FontWeight.w500,
                color: numberColor,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              lunarText,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(fontSize: 10, height: 1.15, color: subColor),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: events.take(3).map((e) {
                  return Container(
                    width: 4.5,
                    height: 4.5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: inMonth
                          ? categoryColor(e.category)
                          : categoryColor(e.category).withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
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
    final leap = lunar.getMonth() < 0 ? '闰' : '';

    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${date.month}月${date.day}日',
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: T.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${weekdayCN(date)}  ·  农历$leap${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}',
                      style: T.bodyMuted,
                    ),
                  ],
                ),
              ),
              if (info.jieQi.isNotEmpty) JieQiTag(info.jieQi),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${lunar.getYearInGanZhi()}年  ${lunar.getMonthInGanZhi()}月  ${lunar.getDayInGanZhi()}日',
            style: const TextStyle(
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: T.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '道历${daoYearCN(date.year)}年  ·  属${lunar.getYearShengXiao()}',
            style: T.caption,
          ),
          const SizedBox(height: 14),
          const InkRule(),
          const SizedBox(height: 12),
          if (info.events.isEmpty)
            const _QuietDay()
          else
            ...[
              for (var i = 0; i < info.events.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                EventTile(event: info.events[i]),
              ],
            ],
        ],
      ),
    );
  }
}

class _QuietDay extends StatelessWidget {
  const _QuietDay();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本日清静',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: T.inkSoft,
            ),
          ),
          SizedBox(height: 2),
          Text('无神诞、下降与节会', style: T.caption),
        ],
      ),
    );
  }
}
