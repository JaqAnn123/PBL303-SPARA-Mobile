import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_notification.dart';

/// Menampilkan notifikasi sistem (status bar HP) memakai
/// `flutter_local_notifications`.
///
/// Notifikasi dipicu oleh [NotificationCenter] saat ada aktivitas baru dari
/// backend, jadi tidak memerlukan Firebase/FCM.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const String channelId = 'spara_status_peminjaman';
  static const String channelName = 'Status Peminjaman';
  static const String channelDescription =
      'Pemberitahuan status pengajuan peminjaman ruangan dan alat.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _enabled = !kIsWeb;
  bool _permissionRequested = false;

  /// Dipanggil saat pengguna mengetuk notifikasi di status bar.
  ValueChanged<int>? onNotificationTap;

  /// Nonaktifkan plugin saat widget test (tidak ada platform channel).
  @visibleForTesting
  void disableForTesting() {
    _enabled = false;
    _initialized = false;
    _permissionRequested = false;
    onNotificationTap = null;
  }

  @visibleForTesting
  void resetForTesting() {
    _enabled = !kIsWeb;
    _initialized = false;
    _permissionRequested = false;
    onNotificationTap = null;
  }

  Future<void> init() async {
    if (!_enabled || _initialized) return;
    try {
      const android = AndroidInitializationSettings('ic_stat_spara');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
        onDidReceiveNotificationResponse: _onResponse,
      );

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
          playSound: true,
        ),
      );
      _initialized = true;
    } catch (error) {
      debugPrint('Gagal menyiapkan notifikasi lokal: $error');
    }
  }

  /// Minta izin notifikasi (Android 13+ / iOS). Aman dipanggil berkali-kali.
  Future<void> requestPermission() async {
    if (!_enabled) return;
    await init();
    if (!_initialized || _permissionRequested) return;
    _permissionRequested = true;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (error) {
      debugPrint('Gagal meminta izin notifikasi: $error');
    }
  }

  Future<void> show(AppNotification notification) async {
    if (!_enabled) return;
    await init();
    if (!_initialized) return;
    final body = notification.plainMessage;
    try {
      await _plugin.show(
        id: notification.id,
        title: notification.title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_stat_spara',
            color: const Color(0xFF197B47),
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentList: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
        payload: '${notification.id}',
      );
    } catch (error) {
      debugPrint('Gagal menampilkan notifikasi: $error');
    }
  }

  void _onResponse(NotificationResponse response) {
    final id = int.tryParse(response.payload ?? '');
    if (id != null) onNotificationTap?.call(id);
  }
}
