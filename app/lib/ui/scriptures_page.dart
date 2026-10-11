import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

import '../app_state.dart';
import '../rules_engine.dart';
import '../theme.dart';

class ScripturesPage extends StatelessWidget {
  final AppState state;
  const ScripturesPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final engine = state.engine!;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text('经典与神尊',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('主要经典所属神尊的圣诞、下降与斋期，点按查看详情与下次日期。',
                style: TextStyle(fontSize: 13, color: T.muted)),
          ),
          ...state.scriptures.map((s) => Card(
                child: ListTile(
                  title: Text(s.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      s.common.isEmpty ? s.deity : '${s.common} · ${s.deity}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right, color: T.muted),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) =>
                          ScriptureDetail(engine: engine, scripture: s))),
                ),
              )),
        ],
      ),
    );
  }
}

class ScriptureDetail extends StatelessWidget {
  final RulesEngine engine;
  final Scripture scripture;

  const ScriptureDetail({super.key, required this.engine, required this.scripture});

  String _fmt(DateTime? d) =>
      d == null ? '待查' : '${d.year}年${d.month}月${d.day}日';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final rows = <Widget>[];

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
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 7),
              width: 6,
              height: 6,
              decoration:
                  const BoxDecoration(color: T.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15)),
                  Text('$cycle · 下次：${_fmt(when)}',
                      style: const TextStyle(fontSize: 12, color: T.muted)),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(scripture.common.isEmpty ? scripture.title : scripture.common),
        backgroundColor: T.paper,
        foregroundColor: T.ink,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(scripture.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(scripture.deity,
              style: const TextStyle(
                  fontSize: 13, color: T.accent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(scripture.desc, style: const TextStyle(fontSize: 14, height: 1.6)),
          const Divider(height: 28),
          const Text('相关日期',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...rows,
          if (scripture.benming != null) ...[
            const Divider(height: 28),
            const Text('本命星君（按生年地支）',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: scripture.benming!
                  .map((b) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: T.line),
                        ),
                        child: Text('${b['zhi']}年 · ${b['star']}',
                            style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            const Text(
                '本命日：依生年地支所属本命星君，于其下降日或九皇会其降世之日诵《北斗经》，祈福延生。',
                style: TextStyle(fontSize: 12, color: T.muted, height: 1.5)),
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
