import 'package:lunar/lunar.dart';

/// 单条道历事件
class DaoEvent {
  final String name;
  final String category; // 神诞/下降/升真/斋戒/节会/节日/纪事

  const DaoEvent(this.name, this.category);

  @override
  bool operator ==(Object other) => other is DaoEvent && other.name == name;
  @override
  int get hashCode => name.hashCode;
}

/// 提醒分组（订阅粒度）
class ReminderGroup {
  final String id;
  final String label;
  final String desc;
  final bool defaultOn;
  const ReminderGroup(this.id, this.label, this.desc, this.defaultOn);
}

class ReminderGroups {
  static const shengdan = ReminderGroup('shengdan', '神诞圣诞', '诸神圣诞、千秋万寿之日', true);
  static const xiajiang = ReminderGroup('xiajiang', '诸神下降', '每月下降日：北斗、诸斗、天曹、天蓬、天猷、翊圣等', true);
  static const jiuhuang = ReminderGroup('jiuhuang', '北斗九皇降世', '九月初一至初九，九皇星君逐日降世', true);
  static const zhaijie = ReminderGroup('zhaijie', '斋戒戊日', '明戊日、暗戊日等斋戒禁忌之日', true);
  static const jiehui = ReminderGroup('jiehui', '节会节日', '三元、三会、五腊、八节、八会、天赦及民俗节日', true);
  static const other = ReminderGroup('other', '升真纪事', '祖师飞升、历代真人纪事等（较杂）', false);
  static const all = <ReminderGroup>[shengdan, xiajiang, jiuhuang, zhaijie, jiehui, other];

  static ReminderGroup? byId(String id) =>
      all.where((g) => g.id == id).firstOrNull;
}

/// 事件分类 -> 提醒分组
ReminderGroup groupOf(DaoEvent e) {
  final n = e.name;
  if (n == '北斗九皇降世之辰' || n.endsWith('星君降世')) return ReminderGroups.jiuhuang;
  switch (e.category) {
    case '神诞':
      return ReminderGroups.shengdan;
    case '下降':
      return ReminderGroups.xiajiang;
    case '斋戒':
      return ReminderGroups.zhaijie;
    case '节会':
    case '节日':
      return ReminderGroups.jiehui;
    default:
      return ReminderGroups.other;
  }
}

/// 一天的完整信息
class DayInfo {
  final DateTime date;
  final Lunar lunar;
  final List<DaoEvent> events;

  DayInfo(this.date, this.lunar, this.events);

  bool get isLeapMonth => lunar.getMonth() < 0;
  int get lunarMonth => lunar.getMonth().abs();
  int get lunarDay => lunar.getDay();
  String get jieQi => lunar.getJieQi();
}

/// 道历年份 = 公历年 + 2697
const int daoEraOffset = 2697;

const _digits = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

String daoYearCN(int solarYear) {
  final y = (solarYear + daoEraOffset).toString();
  return y.split('').map((c) => _digits[int.parse(c)]).join();
}

/// 分类配色（朱砂、黛蓝、藤黄、赭石、青灰、墨、苍）
const categoryColors = <String, int>{
  '神诞': 0xFF93483E, // 朱砂
  '下降': 0xFF3D5A80, // 黛蓝
  '节会': 0xFF6B705C, // 苍绿
  '斋戒': 0xFF8A5A2B, // 赭石
  '升真': 0xFF52796F, // 青
  '节日': 0xFFB08968, // 藤黄褐
  '纪事': 0xFF8A857A, // 灰
};
