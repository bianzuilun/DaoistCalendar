import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:lunar/lunar.dart';

import 'models.dart';

/// 九皇降世逐日星君
class NineEmperor {
  final int day;
  final String star; // 贪狼
  final String pavilion; // 天枢
  final String title; // 阳明
  final String event; // 北斗第一阳明贪狼星君降世
  const NineEmperor(this.day, this.star, this.pavilion, this.title, this.event);
}

/// 离线规则库：农历年节、每月下降、戊日斋戒、节气锚定、八会干支锚等规则，
/// 含九皇逐日星君等典籍补全条目。纯计算，可外推任意年份。
class RulesEngine {
  final Map<String, Map<String, dynamic>> catalog;
  final Map<String, List<String>> annualLunar; // 'M-D' -> events
  final Map<String, List<String>> monthlyLunar; // 'D' -> events
  final Map<int, String> anWuBranch; // 农历月 -> 暗戊地支
  final List<Map<String, String>> tianShe; // [{term, gz}]
  final Map<String, String> baHui; // 干支 -> 会名
  final Map<String, List<List<int>>> fixed; // 三会/三元/五腊
  final Map<String, List<String>> termEvents; // 节气 -> 事件
  final Set<String> baJieTerms;
  final List<NineEmperor> nineEmperors;

  const RulesEngine({
    required this.catalog,
    required this.annualLunar,
    required this.monthlyLunar,
    required this.anWuBranch,
    required this.tianShe,
    required this.baHui,
    required this.fixed,
    required this.termEvents,
    required this.baJieTerms,
    required this.nineEmperors,
  });

  static Future<RulesEngine> loadFromAssets() async {
    final raw = await rootBundle.loadString('assets/data/rules.json');
    return fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  static RulesEngine fromJson(Map<String, dynamic> j) {
    final annual = <String, List<String>>{};
    for (final r in (j['annual_lunar'] as List)) {
      final m = r['m'] as int;
      final d = r['d'] as int;
      annual['$m-$d'] = (r['events'] as List).cast<String>();
    }
    final monthly = <String, List<String>>{};
    (j['monthly_lunar'] as Map<String, dynamic>).forEach((k, v) {
      monthly[k] = (v as List).cast<String>();
    });
    final anWu = <int, String>{};
    (j['special']['an_wu_branch'] as Map<String, dynamic>)
        .forEach((k, v) => anWu[int.parse(k)] = v as String);
    final fixed = <String, List<List<int>>>{};
    (j['special']['fixed'] as Map<String, dynamic>).forEach((k, v) {
      fixed[k] = (v as List).map((e) => (e as List).cast<int>()).toList();
    });
    final termEvents = <String, List<String>>{};
    (j['term_events'] as Map<String, dynamic>).forEach((k, v) {
      termEvents[k] = (v as List).cast<String>();
    });
    final emperors = (j['nine_emperors'] as List)
        .map((e) => NineEmperor(e['day'] as int, e['star'] as String,
            e['pavilion'] as String, e['title'] as String, e['event'] as String))
        .toList();
    return RulesEngine(
      catalog: (j['catalog'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as Map<String, dynamic>)),
      annualLunar: annual,
      monthlyLunar: monthly,
      anWuBranch: anWu,
      tianShe: (j['special']['tian_she'] as List)
          .map((e) => (e as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as String)))
          .toList(),
      baHui: (j['special']['ba_hui'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as String)),
      fixed: fixed,
      termEvents: termEvents,
      baJieTerms: ((j['ba_jie_terms'] as List)).cast<String>().toSet(),
      nineEmperors: emperors,
    );
  }

  static int _solarNum(Solar s) =>
      s.getYear() * 10000 + s.getMonth() * 100 + s.getDay();

  /// 计算某日的全部道历事件（已按目录归类、去重）
  List<DaoEvent> eventsFor(Lunar lunar) {
    final names = <String>{};
    final lm = lunar.getMonth();
    final ld = lunar.getDay();
    final lmAbs = lm.abs();

    if (lm > 0) {
      // 农历年节与每月下降规则（闰月不套用）
      annualLunar['$lmAbs-$ld']?.forEach(names.add);
      monthlyLunar['$ld']?.forEach(names.add);
      for (final e in fixed.entries) {
        if (e.value.any((p) => p[0] == lmAbs && p[1] == ld)) names.add(e.key);
      }
      if (anWuBranch[lmAbs] == lunar.getDayZhi()) names.add('暗戊日');
      if (lunar.getDayGan() == '戊') names.add('明戊日');
      if (lmAbs == 9 && ld >= 1 && ld <= 9) {
        names.add('北斗九皇降世之辰');
        names.add(nineEmperors[ld - 1].event);
      }
    }

    final gz = lunar.getDayInGanZhi();
    final hui = baHui[gz];
    if (hui != null) {
      names.add(hui);
      names.add('八会日');
    }
    if (_isTianShe(lunar, gz)) names.add('天赦日');

    final jq = lunar.getJieQi();
    if (baJieTerms.contains(jq)) {
      names.add('八节日');
      termEvents[jq]?.forEach(names.add);
    }

    final events = <DaoEvent>[];
    for (final n in names) {
      final cat = catalog[n]?['category'] as String? ?? '纪事';
      events.add(DaoEvent(n, cat));
    }
    // 排序：神诞 > 下降 > 节会 > 斋戒 > 升真 > 节日 > 纪事
    const order = ['神诞', '下降', '节会', '斋戒', '升真', '节日', '纪事'];
    events.sort((a, b) => order.indexOf(a.category)
        .compareTo(order.indexOf(b.category)));
    return events;
  }

  DayInfo dayInfo(DateTime date) {
    final solar = Solar.fromYmd(date.year, date.month, date.day);
    final lunar = solar.getLunar();
    return DayInfo(date, lunar, eventsFor(lunar));
  }

  /// 天赦日：春戊寅、夏甲午、秋戊申、冬甲子（节气区间）
  bool _isTianShe(Lunar lunar, String dayGZ) {
    final table = lunar.getJieQiTable();
    for (final rule in tianShe) {
      if (rule['gz'] != dayGZ) continue;
      final seasonStart = table[rule['term']!];
      if (seasonStart == null) continue;
      final spans = <String, List<String>>{
        '立春': ['立春', '立夏'],
        '立夏': ['立夏', '立秋'],
        '立秋': ['立秋', '立冬'],
        '立冬': ['立冬', '立春'],
      };
      final pair = spans[rule['term']]!;
      final a = table[pair[0]];
      final b = table[pair[1]];
      if (a == null || b == null) continue;
      final me = _solarNum(lunar.getSolar());
      final da = _solarNum(a);
      final db = _solarNum(b);
      if (db <= da) {
        // 立冬→次年立春 跨年
        if (me >= da || me < db) return true;
      } else if (me >= da && me < db) {
        return true;
      }
    }
    return false;
  }

  /// 某农历月日未来的第一次出现（供经典页展示日期）
  DateTime? nextAnnualOccurrence(DateTime from, int m, int d) {
    var cur = DateTime(from.year, from.month, from.day);
    for (var i = 0; i < 420; i++) {
      final lunar = Solar.fromYmd(cur.year, cur.month, cur.day).getLunar();
      if (lunar.getMonth() > 0 &&
          lunar.getMonth().abs() == m &&
          lunar.getDay() == d) {
        return cur;
      }
      cur = cur.add(const Duration(days: 1));
    }
    return null;
  }

  /// 某节气未来第一次出现
  DateTime? nextTermOccurrence(DateTime from, String term) {
    for (var y = from.year; y <= from.year + 2; y++) {
      final table =
          Solar.fromYmd(y, 6, 1).getLunar().getJieQiTable();
      final s = table[term];
      if (s == null) continue;
      final d = DateTime(s.getYear(), s.getMonth(), s.getDay());
      if (!d.isBefore(DateTime(from.year, from.month, from.day))) return d;
    }
    return null;
  }

  /// 未来 n 天内命中规则的事件（供提醒排期与预览）
  List<DayInfo> expand(DateTime from, int days) {
    final out = <DayInfo>[];
    for (var i = 0; i < days; i++) {
      final d = DateTime(from.year, from.month, from.day).add(Duration(days: i));
      final info = dayInfo(d);
      if (info.events.isNotEmpty) out.add(info);
    }
    return out;
  }
}
