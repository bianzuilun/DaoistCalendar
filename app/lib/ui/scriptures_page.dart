import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

import '../app_state.dart';
import '../rules_engine.dart';
import '../theme.dart';
import 'widgets.dart';

class ScripturesPage extends StatelessWidget {
  final AppState state;
  const ScripturesPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final engine = state.engine!;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const PageHeader(
            title: '经典',
            subtitle: '常诵经籍与所属神尊。点开可看圣诞、下降与下次日期。',
          ),
          ...state.scriptures.map((s) {
            final name = s.common.isEmpty ? s.title : s.common;
            return PaperCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScriptureDetail(engine: engine, scripture: s),
                ),
              ),
              child: Row(
                children: [
                  SealMark(name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: T.heading),
                        if (s.common.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: T.caption,
                          ),
                        ],
                        if (s.deity.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            _shortDeity(s.deity),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, height: 1.3, color: T.inkSoft),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: T.muted, size: 20),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

String _shortDeity(String deity) {
  final i = deity.indexOf('（');
  if (i > 0) return deity.substring(0, i);
  final j = deity.indexOf('(');
  if (j > 0) return deity.substring(0, j);
  return deity;
}

class ScriptureDetail extends StatelessWidget {
  final RulesEngine engine;
  final Scripture scripture;

  const ScriptureDetail({super.key, required this.engine, required this.scripture});

  String _fmt(DateTime? d) => d == null ? '待查' : '${d.year}年${d.month}月${d.day}日';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final rows = <_DateRow>[];

    for (final d in scripture.dates) {
      final type = d['type'] as String;
      final label = d['label'] as String;
      DateTime? when;
      String cycle;
      switch (type) {
        case 'annual':
          when = engine.nextAnnualOccurrence(now, d['m'] as int, d['d'] as int);
          cycle = '每年 · 农历${_cnMonth(d['m'] as int)}${_cnDay(d['d'] as int)}';
          break;
        case 'monthly':
          final days = (d['days'] as List).cast<int>();
          when = _nextMonthly(now, days);
          cycle = '每月 · ${days.map(_cnDay).join('、')}';
          break;
        case 'term':
          when = engine.nextTermOccurrence(now, d['term'] as String);
          cycle = '每年 · ${d['term']}';
          break;
        case 'range':
          when = engine.nextAnnualOccurrence(now, d['m'] as int, d['d1'] as int);
          cycle =
              '每年 · 农历${_cnMonth(d['m'] as int)}${_cnDay(d['d1'] as int)}至${_cnDay(d['d2'] as int)}';
          break;
        default:
          cycle = '';
      }
      rows.add(_DateRow(label: label, cycle: cycle, when: _fmt(when)));
    }

    final barTitle = scripture.common.isEmpty ? scripture.title : scripture.common;

    return Scaffold(
      appBar: AppBar(title: Text(barTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(scripture.title, style: T.title.copyWith(fontSize: 24)),
          if (scripture.deity.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              scripture.deity,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: T.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (scripture.desc.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: T.paperDeep.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  left: BorderSide(color: T.accent.withValues(alpha: 0.75), width: 2.5),
                ),
              ),
              child: Text(scripture.desc, style: T.body),
            ),
          ],
          const SizedBox(height: 22),
          const SectionLabel('相关日期'),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PaperCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.label, style: const TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w600)),
                      if (row.cycle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(row.cycle, style: T.caption),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: T.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '下次',
                              style: TextStyle(
                                fontSize: 11,
                                color: T.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            row.when,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: T.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          if (scripture.benming != null) ...[
            const SizedBox(height: 12),
            const SectionLabel('本命星君'),
            const Text('按生年地支', style: T.caption),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 8.0;
                final width = (constraints.maxWidth - gap * 2) / 3;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: scripture.benming!
                      .map((b) => SizedBox(
                            width: width,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                              decoration: BoxDecoration(
                                color: T.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: T.line),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    b['zhi'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: T.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    b['star'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, height: 1.3, color: T.inkSoft),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              '本命日依生年地支所属星君，于其下降日或九皇会降世之日诵《北斗经》，祈福延生。',
              style: T.caption,
            ),
          ],
        ],
      ),
    );
  }

  DateTime? _nextMonthly(DateTime now, List<int> days) {
    var cur = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 120; i++) {
      final lunar = Solar.fromYmd(cur.year, cur.month, cur.day).getLunar();
      if (lunar.getMonth() > 0 && days.contains(lunar.getDay())) return cur;
      cur = cur.add(const Duration(days: 1));
    }
    return null;
  }

  String _cnMonth(int m) {
    const names = ['正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊'];
    return '${names[m - 1]}月';
  }

  String _cnDay(int d) {
    if (d == 10) return '初十';
    if (d == 20) return '二十';
    if (d == 30) return '三十';
    const pre = ['初', '十', '廿', '三'];
    return '${pre[d ~/ 10]}${'一二三四五六七八九十'[d % 10 - 1]}';
  }
}

class _DateRow {
  final String label;
  final String cycle;
  final String when;
  const _DateRow({required this.label, required this.cycle, required this.when});
}
