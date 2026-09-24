import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:vrijdag/features/auth/domain/profile_defaults.dart';
import 'package:vrijdag/features/calendar/domain/reminder_schedule.dart';

/// One local notification for an event offset.
class ReminderNotice {
  const ReminderNotice({
    required this.id,
    required this.when,
    required this.title,
  });

  final int id;
  final DateTime when;
  final String title;
}

/// Schedules event reminders on this device. Never logs titles.
class LocalReminderNotifications {
  LocalReminderNotifications({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  var _ready = false;

  Future<bool> requestPermission() async {
    try {
      await _ensureReady();
      if (kIsWeb) {
        return false;
      }
      if (Platform.isIOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        return await ios?.requestPermissions(
              alert: true,
              badge: false,
              sound: true,
            ) ??
            false;
      }
      if (Platform.isMacOS) {
        final mac = _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        return await mac?.requestPermissions(
              alert: true,
              badge: false,
              sound: true,
            ) ??
            false;
      }
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.requestNotificationsPermission() ?? false;
      }
    } on Object {
      return false;
    }
    return false;
  }

  /// Drops previous preset offsets for [eventId], then schedules [notices].
  Future<void> replace({
    required String eventId,
    required String channelName,
    required List<ReminderNotice> notices,
  }) async {
    await _ensureReady();
    for (final minutes in reminderPresetMinutes) {
      await _plugin.cancel(id: reminderNotificationId(eventId, minutes));
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'vrijdag_reminders',
        channelName,
        channelDescription: channelName,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
    for (final notice in notices) {
      await _plugin.zonedSchedule(
        id: notice.id,
        title: notice.title,
        body: '',
        scheduledDate: tz.TZDateTime.from(notice.when.toUtc(), tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> clear(String eventId) async {
    try {
      await _ensureReady();
      for (final minutes in reminderPresetMinutes) {
        await _plugin.cancel(id: reminderNotificationId(eventId, minutes));
      }
    } on Object {
      // A missing plugin must not block saving the event.
    }
  }

  Future<void> _ensureReady() async {
    if (_ready) {
      return;
    }
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await resolveDeviceTimezoneId()));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _ready = true;
  }
}
