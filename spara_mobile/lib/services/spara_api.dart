import 'api_client.dart';
import '../models/app_user.dart';
import '../models/facility_model.dart';

/// Kumpulan pemanggilan endpoint backend SPARA.
class SparaApi {
  SparaApi._();

  static final SparaApi instance = SparaApi._();

  ApiClient get _client => ApiClient.instance;

  dynamic _unwrap(dynamic response) {
    if (response is Map && response.containsKey('data')) {
      return response['data'];
    }
    return response;
  }

  List<dynamic> _asList(dynamic value) {
    final data = _unwrap(value);
    if (data is List) return data;
    return const [];
  }

  // ── Auth ────────────────────────────────────────────────────────────────

  Future<({String token, AppUser user})> login({
    required String idNumber,
    required String password,
  }) async {
    final response = await _client.post('/login', {
      'id_number': idNumber,
      'password': password,
    });
    if (response is! Map) {
      throw ApiException('Response login tidak dikenali.');
    }
    final token = '${response['access_token'] ?? ''}';
    final rawUser = response['user'];
    if (token.isEmpty || rawUser is! Map) {
      throw ApiException(
        '${response['message'] ?? 'Login gagal.'}',
      );
    }
    return (token: token, user: AppUser.fromJson(Map<String, dynamic>.from(rawUser)));
  }

  Future<void> register({
    required String idNumber,
    required String name,
    required String email,
    required String phoneNumber,
    required int studyProgramId,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.post('/register', {
      'id_number': idNumber,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'study_program_id': studyProgramId,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<AppUser> me() async {
    final response = await _client.get('/me');
    final data = _unwrap(response);
    if (data is Map) {
      final rawUser = data['user'];
      if (rawUser is Map) {
        return AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      }
    }
    throw ApiException('Tidak dapat memuat data profil.');
  }

  Future<void> logout() async {
    try {
      await _client.post('/logout');
    } on ApiException {
      // Token mungkin sudah kedaluwarsa; abaikan.
    }
  }

  Future<AppUser> updatePhone(String phoneNumber) async {
    final response = await _client.post('/update-profile-phone', {
      'phone_number': phoneNumber,
    });
    return _userFromResponse(response);
  }

  Future<AppUser> updateEmail(String email) async {
    final response = await _client.post('/update-profile-email', {
      'email': email,
    });
    return _userFromResponse(response);
  }

  Future<AppUser> _userFromResponse(dynamic response) async {
    final data = _unwrap(response);
    if (data is Map) {
      final rawUser = data['user'] ?? data;
      if (rawUser is Map && rawUser['id_number'] != null) {
        return AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      }
    }
    return me();
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    await _client.post('/update-password', {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': confirmation,
    });
  }

  // ── Master data ─────────────────────────────────────────────────────────

  Future<List<Facility>> getRuangan() async {
    final response = await _client.get('/get-ruangan');
    return _asList(response)
        .whereType<Map>()
        .map((e) => Facility.fromRuangan(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Facility>> getAlat() async {
    final response = await _client.get('/get-alat');
    return _asList(response)
        .whereType<Map>()
        .map((e) => Facility.fromAlat(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Facility>> getFacilities() async {
    final results = await Future.wait([getRuangan(), getAlat()]);
    return [...results[0], ...results[1]];
  }

  Future<List<Map<String, dynamic>>> getProgramStudi() async {
    final response = await _client.get('/get-program-studi');
    return _asList(response)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPenanggungJawab() async {
    final response = await _client.get('/penanggung-jawab');
    final data = _unwrap(response);
    if (data is Map && data['penanggung_jawab'] is List) {
      return (data['penanggung_jawab'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return _asList(response)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ── Peminjaman ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createPeminjaman({
    required String nameKegiatan,
    required String jenisKegiatan,
    required DateTime tanggal,
    required String jamMulai,
    required String jamSelesai,
    required String idNumberPenanggungJawab,
    int? idRuangan,
    int? idAlat,
    DateTime? tanggalSelesai,
    String? keterangan,
  }) async {
    String two(int value) => value.toString().padLeft(2, '0');
    String fmt(DateTime d) =>
        '${d.year}-${two(d.month)}-${two(d.day)}';
    final date = fmt(tanggal);
    final endDate = fmt(tanggalSelesai ?? tanggal);

    final response = await _client.post('/peminjaman', {
      'name_kegiatan': nameKegiatan,
      'jenis_kegiatan': jenisKegiatan,
      'hari_tanggal': date,
      'tanggal_mulai': date,
      'tanggal_selesai': endDate,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'keterangan': keterangan,
      if (idRuangan != null) 'id_ruangan': idRuangan,
      if (idAlat != null) 'id_alat': idAlat,
      'id_number_penanggungjawab': idNumberPenanggungJawab,
    });
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return const {};
  }

  Future<List<Map<String, dynamic>>> getRiwayat() async {
    final response = await _client.get('/riwayat');
    return _asList(response)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> cancelPeminjaman(int id) async {
    await _client.post('/peminjaman-batal/$id');
  }
}
