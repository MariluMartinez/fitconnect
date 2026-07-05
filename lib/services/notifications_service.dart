import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    await Permission.notification.request();
  }

  static Future<void> scheduleMeetupReminder({
    required int id,
    required String title,
    required String location,
    required DateTime meetupTime,
  }) async {
    final reminderTime = meetupTime.subtract(const Duration(hours: 1));

    if (reminderTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      'FitConnect Reminder',
      '$title starts in 1 hour at $location',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meetup_reminders',
          'Meetup Reminders',
          channelDescription: 'FitConnect meetup reminders',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }
}
