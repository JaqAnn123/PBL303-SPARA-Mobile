import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/app_notification.dart';
import 'api_client.dart';
import 'local_notification_service.dart';
import 'spara_api.dart';

/// Mengambil notifikasi aktivitas dari backend secara berkala.
///
/// Setiap ada notifikasi baru (belum pernah terlihat di sesi ini), notifikasi
/// sistem juga ditampilkan lewat [LocalNotificationService].
class NotificationCenter extends ChangeNotifier with WidgetsBindingObserver {
  NotificationCenter._();

  static final NotificationCenter instance = NotificationCenter._();

  /// Interval pengecekan, sama seperti halaman web (15 detik).
  static const Duration pollInterval = Duration(seconds: 15);

  final List<AppNotification> _items = <AppNotification>[];
  final Set<int> _knownIds = <int>{};

  Timer? _timer;
  bool _active = false;
  bool _refreshing = false;
  bool _loading = false;
  bool _primed = false;
  String? _error;

  List<AppNotification> get items => List.unmodifiable(_items);

  bool get isLoading => _loading;

  bool get isRefreshing => _refreshing;

  String? get error => _error;

  int get unreadCount => _items.where((item) => !item.isRead).length;

  bool get hasUnread => unreadCount > 0;

  /// Mulai pengecekan berkala. Aman dipanggil lebih dari sekali.
  Future<void> start() async {
    if (_active) return;
    _active = true;
    _items.clear();
    _knownIds.clear();
    _error = null;
    _loading = true;
    _primed = false;
    notifyListeners();

    WidgetsBinding.instance.addObserver(this);

    await LocalNotificationService.instance.init();
    await LocalNotificationService.instance.requestPermission();

    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => refresh());
    await refresh(announceNew: false);
  }

  /// Ambil daftar notifikasi terbaru.
  ///
  /// [announceNew] diatur `false` pada pemuatan pertama agar notifikasi lama
  /// tidak memunculkan notifikasi HP saat aplikasi baru dibuka.
  Future<void> refresh({bool announceNew = true}) async {
    if (!_active || _refreshing) return;
    _refreshing = true;
    try {
      final fresh = await SparaApi.instance.getNotifications();
      final freshIds = fresh.map((item) => item.id).toSet();

      if (_primed && announceNew) {
        for (final item in fresh) {
          final isNew = !_knownIds.contains(item.id);
          if (isNew && !item.isRead) {
            await LocalNotificationService.instance.show(item);
          }
        }
      }

      _knownIds
        ..clear()
        ..addAll(freshIds);
      _primed = true;

      _items
        ..clear()
        ..addAll(fresh);
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Gagal memuat notifikasi.';
    } finally {
      _refreshing = false;
      _loading = false;
      if (_active) notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || _items[index].isRead) return;
    _items[index] = _items[index].copyWith(readAt: DateTime.now());
    notifyListeners();
    try {
      await SparaApi.instance.markNotificationRead(id);
    } catch (_) {
      // Biarkan tampilan optimistis; refresh berikutnya menyinkronkan ulang.
    }
  }

  Future<void> markAllRead() async {
    if (!hasUnread) return;
    final now = DateTime.now();
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isRead) {
        _items[i] = _items[i].copyWith(readAt: now);
      }
    }
    notifyListeners();
    try {
      await SparaApi.instance.markAllNotificationsRead();
    } catch (_) {
      // Sama seperti markRead: sinkronisasi ulang saat refresh berikutnya.
    }
  }

  /// Hentikan polling dan kosongkan daftar (dipanggil saat logout/pindah akun).
  void stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    final hadData =
        _items.isNotEmpty || _knownIds.isNotEmpty || _loading || _error != null;
    _items.clear();
    _knownIds.clear();
    _primed = false;
    _loading = false;
    _refreshing = false;
    _error = null;
    if (hadData) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _active) {
      refresh();
    }
  }
}
