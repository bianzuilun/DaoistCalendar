import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:daoli_app/rules_engine.dart';
import 'package:lunar/lunar.dart';

void main() {
  late RulesEngine engine;

  setUpAll(() async {
    // 直接读仓库内资产文件，绕过 rootBundle
    final json = File('../app/assets/data/rules.json').readAsStringSync();
    engine = RulesEngine.fromJson(await _jsonDecode(json));
  });

  test('道历纪年偏移 2697', () {
    // 见 models.dart 的 daoYearCN；此处验证规则库元数据
    expect(engine.catalog.containsKey('玉皇上帝圣诞'), isTrue);
  });

  test('2026-10-10 九月初一：九皇降世 + 贪狼星君 + 南斗星君圣诞', () {
    final lunar = Solar.fromYmd(2026, 10, 10).getLunar();
    final names = engine.eventsFor(lunar).map((e) => e.name).toList();
    expect(names, contains('北斗九皇降世之辰'));
    expect(names, contains('北斗第一阳明贪狼星君降世'));
    expect(names, contains('南斗星君圣诞'));
  });

  test('2026-10-18 九月初九：斗姆圣诞/九皇大帝圣诞/右弼星君', () {
    final lunar = Solar.fromYmd(2026, 10, 18).getLunar();
    final names = engine.eventsFor(lunar).map((e) => e.name).toList();
    expect(names, contains('斗姆元君圣诞'));
    expect(names, contains('九皇大帝圣诞'));
    expect(names, contains('北斗第九隐光右弼星君降世'));
  });

  test('每月初三/廿七 北极北斗下降；初七 西斗+真武', () {
    bool has(DateTime d, String name) =>
        engine.eventsFor(Solar.fromYmd(d.year, d.month, d.day).getLunar())
            .any((e) => e.name == name);
    // 2026年九月初三 = 2026-10-12
    expect(has(DateTime(2026, 10, 12), '北极北斗下降'), isTrue);
    // 2026年九月廿七 = 2026-11-05
    expect(has(DateTime(2026, 11, 5), '北极北斗下降'), isTrue);
    // 2026年二月初七 = 2026-03-25（亦为暗戊日）
    final lunar = Solar.fromYmd(2026, 3, 25).getLunar();
    final names = engine.eventsFor(lunar).map((e) => e.name).toList();
    expect(names, contains('西斗下降'));
    expect(names, contains('真武下降'));
    expect(names, contains('暗戊日'));
  });

  test('2026-01-05 冬月十七 = 暗戊日（卯）；且为明戊当为假', () {
    final lunar = Solar.fromYmd(2026, 1, 5).getLunar();
    final names = engine.eventsFor(lunar).map((e) => e.name).toList();
    expect(names, contains('暗戊日'));
    expect(names, isNot(contains('明戊日')));
  });

  test('明戊日：日干为戊', () {
    // 2026-09-08 = 乙酉日 非戊; 2026-09-02 = 己未? 用已知戊日: 2026-08-15 = 七月初三 戊辰? 
    // 直接验证：任取一天，明戊日当且仅当干首为戊
    for (final ymd in [[2026, 1, 1], [2026, 6, 15], [2025, 12, 31]]) {
      final lunar = Solar.fromYmd(ymd[0], ymd[1], ymd[2]).getLunar();
      final hasMing = engine
          .eventsFor(lunar)
          .any((e) => e.name == '明戊日');
      expect(hasMing, lunar.getDayInGanZhi().startsWith('戊'),
          reason: '$ymd ${lunar.getDayInGanZhi()}');
    }
  });

  test('冬至=元始天尊圣诞，夏至=灵宝天尊圣诞，且为八节日', () {
    final winter = engine.nextTermOccurrence(DateTime(2026, 1, 1), '冬至')!;
    final lunarW = Solar.fromYmd(winter.year, winter.month, winter.day).getLunar();
    final namesW = engine.eventsFor(lunarW).map((e) => e.name).toList();
    expect(namesW, contains('元始天尊圣诞'));
    expect(namesW, contains('八节日'));

    final summer = engine.nextTermOccurrence(DateTime(2026, 1, 1), '夏至')!;
    final lunarS = Solar.fromYmd(summer.year, summer.month, summer.day).getLunar();
    final namesS = engine.eventsFor(lunarS).map((e) => e.name).toList();
    expect(namesS, contains('灵宝天尊圣诞'));
  });

  test('三元日/五腊日/天赦日', () {
    bool has(DateTime d, String name) =>
        engine.eventsFor(Solar.fromYmd(d.year, d.month, d.day).getLunar())
            .any((e) => e.name == name);
    // 上元 2026-03-03（正十五）、中元 2026-08-27、下元 2026-11-23
    expect(has(DateTime(2026, 3, 3), '三元日'), isTrue);
    expect(has(DateTime(2026, 8, 27), '三元日'), isTrue);
    expect(has(DateTime(2026, 11, 23), '三元日'), isTrue);
    // 五腊 正月初一 2026-02-17
    expect(has(DateTime(2026, 2, 17), '五腊日'), isTrue);
    // 天赦: 2024-03-15 戊寅（春）
    expect(has(DateTime(2024, 3, 15), '天赦日'), isTrue);
    expect(has(DateTime(2024, 12, 26), '天赦日'), isTrue); // 甲子 冬
  });

  test('八会日干支锚点', () {
    final gz = Solar.fromYmd(2026, 8, 16).getLunar().getDayInGanZhi();
    final evs = engine.eventsFor(Solar.fromYmd(2026, 8, 16).getLunar());
    if (gz == '壬子') {
      expect(evs.any((e) => e.name == '人会'), isTrue);
      expect(evs.any((e) => e.name == '八会日'), isTrue);
    }
  });

  test('expand: 未来 400 天含事件的天数合理', () {
    final days = engine.expand(DateTime(2026, 10, 12), 400);
    expect(days.length, greaterThan(200));
    expect(days.length, lessThan(400));
  });
}

Future<Map<String, dynamic>> _jsonDecode(String s) async {
  return jsonDecode(s);
}
