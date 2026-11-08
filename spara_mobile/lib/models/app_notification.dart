/// Satu notifikasi aktivitas peminjaman dari endpoint `/notifications`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.peminjamanId,
    this.readAt,
    this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final int? peminjamanId;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  /// Pesan tanpa tag HTML supaya aman ditampilkan di aplikasi & notifikasi HP.
  String get plainMessage => _stripHtml(message);

  AppNotification copyWith({DateTime? readAt}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      peminjamanId: peminjamanId,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _asInt(json['id']),
      type: '${json['type'] ?? 'menunggu'}',
      title: '${json['judul'] ?? 'Notifikasi'}',
      message: '${json['pesan'] ?? ''}',
      peminjamanId: json['peminjaman_id'] == null
          ? null
          : _asInt(json['peminjaman_id']),
      readAt: _asDate(json['read_at']),
      createdAt: _asDate(json['created_at']),
    );
  }

  String get timeAgo {
    final date = createdAt;
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse('$value')?.toLocal();
  }

  static String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
