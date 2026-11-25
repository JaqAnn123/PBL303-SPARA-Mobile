import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/facility_model.dart';
import '../services/api_client.dart';
import '../services/local_notification_service.dart';
import '../services/notification_center.dart';
import '../services/session.dart';
import '../services/spara_api.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import 'bottom_nav_pages.dart';
import 'facility_detail_page.dart';
import 'riwayat.dart';
import 'profil.dart';

class DasborPage extends StatefulWidget {
  const DasborPage({super.key, this.user});

  final AppUser? user;

  @override
  State<DasborPage> createState() => _DasborPageState();
}

class _DasborPageState extends State<DasborPage> {
  static const int _itemsPerPage = 3;
  static const _pageBackground = Color(0xFFF4F7F6);
  static const _deepTeal = Color(0xFF064B45);

  static const _tabs = [
    (label: 'Ruangan & Laboratorium', icon: Icons.meeting_room_outlined),
    (label: 'Peralatan & Inventaris', icon: Icons.devices_outlined),
  ];

  static const _capacityRanges = [
    (label: '≤ 20 orang', min: 0, max: 20),
    (label: '21–40 orang', min: 21, max: 40),
    (label: '> 40 orang', min: 41, max: 100000),
  ];

  static const _roomFacilityOptions = [
    (label: 'Proyektor', icon: Icons.video_camera_front_outlined),
    (label: 'AC', icon: Icons.ac_unit),
    (label: 'Wi-Fi', icon: Icons.wifi),
    (label: 'Papan Tulis', icon: Icons.draw_outlined),
    (label: 'Komputer', icon: Icons.computer_outlined),
    (label: 'Sound System', icon: Icons.speaker_outlined),
  ];

  static const _equipmentTypes = [
    (
      label: 'Proyektor',
      icon: Icons.video_camera_front_outlined,
      keywords: ['proyektor', 'projector'],
    ),
    (
      label: 'Komputer / Laptop',
      icon: Icons.computer_outlined,
      keywords: ['komputer', 'laptop', 'pc', 'notebook'],
    ),
    (
      label: 'Kamera',
      icon: Icons.photo_camera_outlined,
      keywords: ['kamera', 'camera'],
    ),
    (
      label: 'Audio',
      icon: Icons.mic_none_outlined,
      keywords: ['speaker', 'mikrofon', 'microphone', 'audio', 'sound'],
    ),
    (
      label: 'Papan Tulis',
      icon: Icons.draw_outlined,
      keywords: ['papan', 'whiteboard'],
    ),
  ];

  final GlobalKey _headerKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  double _headerHeight = 220;
  String _query = '';

  int _navIndex = 0;
  int _selectedCategory = 0;
  int _currentPage = 1;

  int? _capacityFilter;
  final Set<String> _roomFacilityFilters = <String>{};
  int? _equipmentFilter;

  @override
  void dispose() {
    NotificationCenter.instance.removeListener(_onNotificationsChanged);
    LocalNotificationService.instance.onNotificationTap = null;
    NotificationCenter.instance.stop();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<_Fac> _allFacilities = const [];
  bool _isLoadingFacilities = true;
  String? _facilitiesError;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user ?? Session.instance.user;
    NotificationCenter.instance.addListener(_onNotificationsChanged);
    LocalNotificationService.instance.onNotificationTap = (_) {
      if (mounted) _showNotifications();
    };
    NotificationCenter.instance.start();
    _loadFacilities();
  }

  void _onNotificationsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _isLoadingFacilities = true;
      _facilitiesError = null;
    });
    try {
      final facilities = await SparaApi.instance.getFacilities();
      if (!mounted) return;
      setState(() {
        _allFacilities = facilities.map(_Fac.from).toList();
        _isLoadingFacilities = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _facilitiesError = e.message;
        _isLoadingFacilities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _facilitiesError = 'Gagal memuat data fasilitas.';
        _isLoadingFacilities = false;
      });
    }
  }

  int _capacityOf(_Fac f) {
    final m = RegExp(r'\d+').firstMatch(f.capacity);
    return int.tryParse(m?.group(0) ?? '') ?? 0;
  }

  bool _matchesEquipment(
    _Fac f,
    ({String label, IconData icon, List<String> keywords}) type,
  ) {
    final n = f.name.toLowerCase();
    return type.keywords.any(n.contains);
  }

  String _equipmentLabelFor(_Fac f) {
    for (final t in _equipmentTypes) {
      if (_matchesEquipment(f, t)) return t.label;
    }
    return 'Lainnya';
  }

  List<String> _tagsFor(_Fac f) =>
      f.type == 'Ruangan' ? f.facilities : <String>[_equipmentLabelFor(f)];

  bool get _hasActiveFilter => _selectedCategory == 0
      ? (_capacityFilter != null || _roomFacilityFilters.isNotEmpty)
      : _equipmentFilter != null;

  void _resetFilters() {
    setState(() {
      if (_selectedCategory == 0) {
        _capacityFilter = null;
        _roomFacilityFilters.clear();
      } else {
        _equipmentFilter = null;
      }
      _currentPage = 1;
    });
  }

  List<_Fac> get _filteredFacilities {
    final isRoom = _selectedCategory == 0;
    final category = isRoom ? 'Ruangan' : 'Peralatan';
    return _allFacilities.where((f) {
      if (f.type != category) return false;
      if (isRoom) {
        if (_capacityFilter != null) {
          final r = _capacityRanges[_capacityFilter!];
          final cap = _capacityOf(f);
          if (cap < r.min || cap > r.max) return false;
        }
        if (_roomFacilityFilters.isNotEmpty) {
          final has = f.facilities;
          if (!_roomFacilityFilters.every(has.contains)) return false;
        }
        return true;
      }
      if (_equipmentFilter == null) return true;
      return _matchesEquipment(f, _equipmentTypes[_equipmentFilter!]);
    }).toList();
  }

  List<_Fac> get _searchResults {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final terms = q.split(RegExp(r'\s+'));
    return _allFacilities.where((f) {
      final hay =
          '${f.name} ${f.id} ${f.type} ${f.building} lantai ${f.floor} ${_tagsFor(f).join(' ')}'
              .toLowerCase();
      return terms.every(hay.contains);
    }).toList();
  }

  int _pageCountFor(int total) =>
      (total / _itemsPerPage).ceil().clamp(1, 999).toInt();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi,';
    if (h < 15) return 'Selamat Siang,';
    if (h < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  AppUser? get _currentUser => Session.instance.user ?? _user;

  String get _displayName {
    final name = _currentUser?.name.trim() ?? '';
    return name.isEmpty ? 'Pengguna SPARA' : name;
  }

  String get _displayInitials {
    final initials = _currentUser?.initials ?? '';
    return initials.isEmpty ? 'SP' : initials;
  }

  Widget _buildHeaderAvatar() {
    final url = ApiClient.instance.mediaUrl(_currentUser?.profilePicture) ?? '';
    final fallback = Container(
      color: const Color(0xFFDDF3EF),
      alignment: Alignment.center,
      child: Text(
        _displayInitials,
        style: const TextStyle(
          color: AppColors.darkTeal,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: 44,
        height: 44,
        child: url.isEmpty
            ? fallback
            : Stack(
                fit: StackFit.expand,
                children: [
                  fallback,
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
      ),
    );
  }

  void _onNavTap(int index) {
    _searchFocus.unfocus();
    setState(() => _navIndex = index);
  }

  void _onBackToDashboard() {
    if (_navIndex != 0) {
      setState(() => _navIndex = 0);
    } else if (_query.isNotEmpty) {
      _clearSearch();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() => _query = '');
  }

  void _goToPage(int page, int pageCount) {
    if (page < 1 || page > pageCount) return;
    setState(() => _currentPage = page);
  }

  void _scheduleHeaderMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final h = box.size.height;
      if ((h - _headerHeight).abs() > 0.5) setState(() => _headerHeight = h);
    });
  }

  void _toast(String message, {IconData icon = Icons.info_outline}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _showNotifications() async {
    final center = NotificationCenter.instance;
    center.refresh();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: ListenableBuilder(
            listenable: center,
            builder: (context, _) {
              final items = center.items;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Notifikasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (center.hasUnread)
                        TextButton(
                          key: const ValueKey('notifications-mark-all-read'),
                          onPressed: center.markAllRead,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.darkTeal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text(
                            'Tandai semua dibaca',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (center.isLoading && items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    )
                  else if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          center.error ?? 'Belum ada notifikasi.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.52,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _buildNotificationItem(center, items[index]),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _onNavTap(2);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkTeal,
                        side: const BorderSide(color: AppColors.darkTeal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Lihat riwayat peminjaman'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationCenter center,
    AppNotification notification,
  ) {
    final style = _notificationStyle(notification.type);
    return Material(
      key: ValueKey('notification-item-${notification.id}'),
      color: notification.isRead ? Colors.white : style.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => center.markRead(notification.id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notification.isRead
                  ? const Color(0xFFE8ECEB)
                  : style.color.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!notification.isRead) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 6),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: style.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.plainMessage,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textGrey,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.timeAgo,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({IconData icon, Color color, Color background}) _notificationStyle(
    String type,
  ) {
    switch (type) {
      case 'disetujui':
        return (
          icon: Icons.check_circle_outline,
          color: const Color(0xFF2E7D32),
          background: const Color(0xFFEAF7EC),
        );
      case 'progress':
        return (
          icon: Icons.autorenew,
          color: const Color(0xFFB26A00),
          background: const Color(0xFFFFF6E5),
        );
      case 'ditolak':
        return (
          icon: Icons.cancel_outlined,
          color: const Color(0xFFB3261E),
          background: const Color(0xFFFDECEA),
        );
      case 'dibatalkan':
        return (
          icon: Icons.warning_amber_outlined,
          color: const Color(0xFFB26A00),
          background: const Color(0xFFFFF6E5),
        );
      default:
        return (
          icon: Icons.schedule_outlined,
          color: const Color(0xFF5F6B69),
          background: const Color(0xFFF1F4F3),
        );
    }
  }

  Future<void> _showFacilityDetail(_Fac f) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FacilityDetailPage(facility: f.toFacility()),
      ),
    );
    if (created == true && mounted) {
      _searchFocus.unfocus();
      setState(() => _navIndex = 0);
      await _loadFacilities();
      if (!mounted) return;
      _toast(
        'Pengajuan ${f.name} berhasil dikirim.',
        icon: Icons.check_circle_outline,
      );
    }
  }

  Future<void> _showSearchFacilityDetail(Facility facility) async {
    await _showFacilityDetail(_Fac.from(facility));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _navIndex == 0 && _query.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBackToDashboard();
      },
      child: Scaffold(
        backgroundColor: _pageBackground,
        body: IndexedStack(
          index: _navIndex,
          children: [
            _buildDashboard(context),
            FacilitySearchPage(onFacilitySelected: _showSearchFacilityDetail),
            const LoanHistoryPage(),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: MainBottomNavBar(
          currentIndex: _navIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    _scheduleHeaderMeasure();
    final searching = _query.trim().isNotEmpty;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: _headerHeight)),
              SliverToBoxAdapter(child: _buildLoanInfoCard()),
              SliverToBoxAdapter(child: _buildRecommendationPanel()),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: ColoredBox(color: Color(0xFF08766C)),
              ),
            ],
          ),
        ),
        if (searching) Positioned.fill(child: _buildSearchResults()),
        Positioned(top: 0, left: 0, right: 0, child: _buildHeader(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final unread = NotificationCenter.instance.unreadCount;
    return Container(
      key: _headerKey,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _onNavTap(3),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _buildHeaderAvatar(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                        ),
                        Text(
                          _displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Badge(
                    key: const ValueKey('dashboard-notification-badge'),
                    isLabelVisible: unread > 0,
                    label: unread > 0 ? Text('$unread') : null,
                    smallSize: 16,
                    backgroundColor: const Color(0xFFFF5252),
                    textColor: Colors.white,
                    alignment: const AlignmentDirectional(22, 9),
                    child: IconButton(
                      key: const ValueKey('dashboard-notifications'),
                      tooltip: 'Notifikasi',
                      onPressed: _showNotifications,
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    const Text(
                      'Mau pinjam apa hari ini?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSearchField(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black26,
      child: SizedBox(
        height: 50,
        child: TextField(
          key: const ValueKey('dashboard-search'),
          controller: _searchController,
          focusNode: _searchFocus,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v),
          onTapOutside: (_) => _searchFocus.unfocus(),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          cursorColor: AppColors.darkTeal,
          decoration: InputDecoration(
            hintText: 'Cari fasilitas kampus...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.darkTeal,
              size: 22,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: _clearSearch,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.accentTeal,
                      size: 20,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _searchResults;
    final q = _query.trim();

    return Container(
      color: _pageBackground,
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, _headerHeight + 16, 16, 24),
        itemCount: results.isEmpty ? 2 : results.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(
                '${results.length} hasil untuk “$q”',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                ),
              ),
            );
          }
          if (results.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: const [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Fasilitas tidak ditemukan',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Coba kata kunci lain, misalnya nama ruangan, gedung, atau alat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12.5),
                  ),
                ],
              ),
            );
          }
          final f = results[i - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 0.5,
              shadowColor: Colors.black26,
              child: InkWell(
                key: ValueKey('search-result-${f.id}'),
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _searchFocus.unfocus();
                  _showFacilityDetail(f);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF6F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          f.type == 'Ruangan'
                              ? Icons.meeting_room_outlined
                              : Icons.devices_outlined,
                          color: AppColors.darkTeal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${f.building} · Lantai ${f.floor} · ${f.type}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoanInfoCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.darkTeal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Informasi Peminjaman Saya',
                    style: TextStyle(
                      color: AppColors.darkTeal,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    icon: Icons.hourglass_top_rounded,
                    title: 'Dalam Proses',
                    value: '8',
                    unit: 'Pengajuan',
                    caption: 'Menunggu disetujui',
                    backgroundColor: const Color(0xFFEAF8F5),
                    foregroundColor: AppColors.darkTeal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    icon: Icons.task_alt_rounded,
                    title: 'Selesai',
                    value: '24',
                    unit: 'Peminjaman',
                    caption: 'Telah selesai dilakukan',
                    backgroundColor: const Color(0xFFEEF1FB),
                    foregroundColor: const Color(0xFF26334F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('dashboard-view-history'),
                onPressed: () => _onNavTap(2),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Lihat Riwayat Lengkap'),
                iconAlignment: IconAlignment.end,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentTeal,
                  minimumSize: const Size(0, 40),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required String caption,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onNavTap(2),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: foregroundColor.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: foregroundColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 32,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: foregroundColor.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                caption,
                style: TextStyle(
                  color: foregroundColor.withValues(alpha: 0.72),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationPanel() {
    final filtered = _filteredFacilities;
    final pageCount = _pageCountFor(filtered.length);
    final page = _currentPage.clamp(1, pageCount).toInt();
    final items = filtered
        .skip((page - 1) * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    final listKey = ValueKey(
      '$_selectedCategory-$page-$_capacityFilter-$_equipmentFilter-'
      '${(_roomFacilityFilters.toList()..sort()).join(",")}',
    );

    return Container(
      key: const ValueKey('recommendation-panel'),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF19796F), Color(0xFF08766C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Color(0xFFFFC107),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Rekomendasi Kilat',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Saran cepat alat/ruangan sesuai dengan kebutuhan Anda.',
                  style: TextStyle(color: Color(0xFFCFE3E0), fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                _buildCategoryTabs(),
                const SizedBox(height: 14),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey('filters-$_selectedCategory'),
                      child: _selectedCategory == 0
                          ? _buildRoomFilters()
                          : _buildEquipmentFilters(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoadingFacilities)
            _buildFacilitiesLoading()
          else if (_facilitiesError != null)
            _buildFacilitiesError()
          else if (items.isEmpty)
            _buildEmptyRecommendation()
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: ListView.builder(
                key: listKey,
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                itemBuilder: (context, index) => _FacilityCard(
                  facility: items[index],
                  tags: _tagsFor(items[index]),
                  onDetail: () => _showFacilityDetail(items[index]),
                  onBorrow: () => _showFacilityDetail(items[index]),
                ),
              ),
            ),
          _buildPagination(page, pageCount, filtered.length),
        ],
      ),
    );
  }

  Widget _buildRoomFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filterHeader('Kapasitas ruangan', showReset: _hasActiveFilter),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_capacityRanges.length, (i) {
            return _filterChip(
              key: ValueKey('capacity-chip-$i'),
              label: _capacityRanges[i].label,
              icon: Icons.people_outline,
              selected: _capacityFilter == i,
              onSelected: (v) => setState(() {
                _capacityFilter = v ? i : null;
                _currentPage = 1;
              }),
            );
          }),
        ),
        const SizedBox(height: 14),
        _filterHeader('Fasilitas dalam ruangan'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opt in _roomFacilityOptions)
              _filterChip(
                key: ValueKey('facility-chip-${opt.label}'),
                label: opt.label,
                icon: opt.icon,
                selected: _roomFacilityFilters.contains(opt.label),
                onSelected: (v) => setState(() {
                  v
                      ? _roomFacilityFilters.add(opt.label)
                      : _roomFacilityFilters.remove(opt.label);
                  _currentPage = 1;
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEquipmentFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filterHeader('Jenis alat', showReset: _hasActiveFilter),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_equipmentTypes.length, (i) {
            final t = _equipmentTypes[i];
            return _filterChip(
              key: ValueKey('equipment-chip-$i'),
              label: t.label,
              icon: t.icon,
              selected: _equipmentFilter == i,
              onSelected: (v) => setState(() {
                _equipmentFilter = v ? i : null;
                _currentPage = 1;
              }),
            );
          }),
        ),
      ],
    );
  }

  Widget _filterHeader(String title, {bool showReset = false}) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (showReset)
            GestureDetector(
              onTap: _resetFilters,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Atur ulang',
                  style: TextStyle(
                    color: Color(0xFFFFC107),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required Key key,
    required String label,
    required IconData icon,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      key: key,
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : AppColors.darkTeal,
      ),
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: _deepTeal,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : _deepTeal,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      showCheckmark: false,
    );
  }

  Widget _buildFacilitiesLoading() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Memuat data fasilitas...',
              style: TextStyle(color: Color(0xFFCFE3E0), fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white70, size: 44),
            const SizedBox(height: 8),
            const Text(
              'Gagal memuat data',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _facilitiesError ?? 'Periksa koneksi ke server.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFCFE3E0), fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _loadFacilities,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                minimumSize: const Size(0, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecommendation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off, color: Colors.white70, size: 44),
            const SizedBox(height: 8),
            const Text(
              'Belum ada rekomendasi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coba kategori lain atau hapus filter.',
              style: TextStyle(color: Color(0xFFCFE3E0), fontSize: 12.5),
            ),
            if (_hasActiveFilter) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Hapus filter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedCategory == i;
          final tab = _tabs[i];
          return Expanded(
            child: GestureDetector(
              key: ValueKey('recommendation-tab-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                _selectedCategory = i;
                _currentPage = 1;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 20,
                      color: selected ? AppColors.darkTeal : Colors.white70,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? _deepTeal : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<int> _pageTokens(int page, int count) {
    if (count <= 5) return List.generate(count, (i) => i + 1);
    final set = <int>{1, count, page - 1, page, page + 1}
      ..removeWhere((p) => p < 1 || p > count);
    final sorted = set.toList()..sort();
    final out = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) out.add(-1);
      out.add(sorted[i]);
    }
    return out;
  }

  Widget _buildPagination(int page, int pageCount, int total) {
    final canPrev = page > 1;
    final canNext = page < pageCount;
    final tokens = _pageTokens(page, pageCount);

    Widget arrow({
      required Key key,
      required String tooltip,
      required IconData icon,
      required VoidCallback? onTap,
    }) {
      final enabled = onTap != null;
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          key: key,
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 24,
              color: enabled ? AppColors.darkTeal : Colors.white38,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    arrow(
                      key: const ValueKey('recommendation-previous'),
                      tooltip: 'Sebelumnya',
                      icon: Icons.chevron_left_rounded,
                      onTap: canPrev
                          ? () => _goToPage(page - 1, pageCount)
                          : null,
                    ),
                    const SizedBox(width: 6),
                    for (final t in tokens)
                      if (t == -1)
                        const SizedBox(
                          width: 26,
                          height: 44,
                          child: Center(
                            child: Text(
                              '…',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        Semantics(
                          button: true,
                          selected: t == page,
                          label: 'Halaman $t',
                          child: GestureDetector(
                            onTap: () => _goToPage(t, pageCount),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: AnimatedContainer(
                                key: ValueKey('recommendation-page-$t'),
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: t == page ? 46 : 40,
                                height: t == page ? 46 : 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: t == page
                                      ? const Color(0xFFFFC107)
                                      : Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    t == page ? 16 : 14,
                                  ),
                                  boxShadow: t == page
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFFC107)
                                                .withValues(alpha: 0.45),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  '$t',
                                  style: TextStyle(
                                    fontSize: t == page ? 16 : 14,
                                    fontWeight: FontWeight.w800,
                                    color: t == page ? _deepTeal : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(width: 6),
                    arrow(
                      key: const ValueKey('recommendation-next'),
                      tooltip: 'Berikutnya',
                      icon: Icons.chevron_right_rounded,
                      onTap: canNext
                          ? () => _goToPage(page + 1, pageCount)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: Color(0xFFCFE3E0),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  const TextSpan(text: 'Halaman '),
                  TextSpan(
                    text: '$page dari $pageCount',
                    style: const TextStyle(
                      color: Color(0xFFFFC107),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: '  ·  $total fasilitas'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F3EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF197B47),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({
    required this.facility,
    required this.tags,
    required this.onDetail,
    required this.onBorrow,
  });

  final _Fac facility;
  final List<String> tags;
  final VoidCallback onDetail;
  final VoidCallback onBorrow;

  static const Color _lihatDetailColor = Color(0xFF2E474C);
  static const Color _pinjamColor = Color(0xFF197B47);

  @override
  Widget build(BuildContext context) {
    final isRoom = facility.type == 'Ruangan';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onDetail,
            child: Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B4F4A), Color(0xFF2C7A72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isRoom
                          ? Icons.meeting_room_outlined
                          : Icons.devices_outlined,
                      size: 56,
                      color: Colors.white38,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.apartment,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          facility.building,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        facility.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F3EC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        facility.id,
                        style: const TextStyle(
                          color: _pinjamColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _infoChip(Icons.people_outline, facility.capacity),
                    _infoChip(Icons.layers_outlined, facility.floor),
                    _infoChip(Icons.category_outlined, facility.type),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final t in tags) _TagChip(label: t)],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: ValueKey('detail-${facility.id}'),
                        onPressed: onDetail,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: _lihatDetailColor,
                            width: 1.5,
                          ),
                          foregroundColor: _lihatDetailColor,
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Lihat Detail'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        key: ValueKey('borrow-${facility.id}'),
                        onPressed: onBorrow,
                        style: FilledButton.styleFrom(
                          backgroundColor: _pinjamColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Pinjam Sekarang →'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5E6B75)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF3F4A52)),
          ),
        ],
      ),
    );
  }
}

class _Fac {
  const _Fac({
    required this.id,
    required this.name,
    required this.type,
    required this.building,
    required this.floor,
    required this.capacity,
    this.dbId,
    this.status = 'Tersedia',
    this.imageUrl,
    this.facilities = const [],
    this.description,
    this.pic,
  });

  factory _Fac.from(Facility f) => _Fac(
    id: f.id,
    name: f.name,
    type: f.type,
    building: f.building,
    floor: f.floor,
    capacity: f.capacity,
    dbId: f.dbId,
    status: f.status,
    imageUrl: f.imageUrl,
    facilities: f.facilities,
    description: f.description,
    pic: f.pic,
  );

  Facility toFacility() => Facility(
    id: id,
    name: name,
    category: id,
    imagePath: 'lib/assets/images/facility/room1.jpg',
    capacity: capacity,
    building: building,
    floor: floor,
    type: type,
    status: status,
    dbId: dbId,
    imageUrl: imageUrl,
    facilities: facilities,
    description: description,
    pic: pic,
  );

  final String id;
  final String name;
  final String type;
  final String building;
  final String floor;
  final String capacity;
  final int? dbId;
  final String status;
  final String? imageUrl;
  final List<String> facilities;
  final String? description;
  final String? pic;
}
