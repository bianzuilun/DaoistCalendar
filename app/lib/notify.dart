import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app_state.dart';

const _channelId = 'daoli_daily';
const _channelName = '道历提醒';
const _channelDesc = '神诞、诸神下降、斋戒戊日、节会节气提醒';

final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
bool _tzReady = false;

void _ensureTz() {
  if (_tzReady) return;
  tzdata.initializeTimeZones();
  try {
    final name = DateTime.now().timeZoneName;
    tz.setLocalLocation(tz.getLocation(name));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
  }
  _tzReady = true;
}

Future<void> initNotifications() async {
  _ensureTz();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios));
}

List<(DateTime, String, String)> _buildSchedule(AppState state) {
  final engine = state.engine;
  if (engine == null) return const [];
  final parts = state.reminderTime.split(':');
  final hh = int.tryParse(parts[0]) ?? 7;
  final mm = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  final out = <(DateTime, String, String)>[];
  for (var i = 0; i < 400; i++) {
    final date = start.add(Duration(days: i));
    final info = engine.dayInfo(date);
    final events = info.events.where(state.shouldRemind).toList();
    if (events.isEmpty) continue;
    final lunarText =
        '${info.lunar.getMonthInChinese()}月${info.lunar.getDayInChinese()}';
    final when = DateTime(date.year, date.month, date.day, hh, mm);
    if (!when.isAfter(DateTime.now())) continue;
    final shown = events.take(6).map((e) => e.name).toList();
    final body =
        shown.join('\n') + (events.length > 6 ? '\n…等${events.length}项' : '');
    out.add((when, '道历 · ${date.month}月${date.day}日 $lunarText', body));
  }
  return out;
}

/// 全量重排未来 400 天的提醒（iOS 限 64 条，取最近日期）
Future<void> rescheduleReminders(AppState state) async {
  await plugin.cancelAll();
  if (!state.remindersEnabled) return;

  // Android 13+ 通知权限
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  final schedule = _buildSchedule(state);
  var id = 1;
  var count = 0;
  for (final (at, title, body) in schedule) {
    // iOS 本地通知上限 64 条
    if (defaultTargetPlatform == TargetPlatform.iOS && count >= 64) break;
    final tzWhen = tz.TZDateTime.from(at, tz.local);
    if (!tzWhen.isAfter(tz.TZDateTime.now(tz.local))) continue;
    await plugin.zonedSchedule(
      id: id++,
      title: title,
      body: body,
      scheduledDate: tzWhen,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    count++;
  }
}
