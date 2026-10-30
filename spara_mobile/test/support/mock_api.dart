import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spara_mobile/models/app_user.dart';
import 'package:spara_mobile/services/api_client.dart';
import 'package:spara_mobile/services/session.dart';

/// User contoh yang dipakai seluruh widget test.
const Map<String, dynamic> testUserJson = {
  'id_number': '2021101001',
  'name': 'Rajiv Tajusa David',
  'email': 'rajivcream@gmail.com',
  'phone_number': '+62 812-3456-7890',
  'role': 'mahasiswa',
  'profile_picture': null,
  'study_program_id': 103,
};

const List<Map<String, dynamic>> testProgramStudi = [
  {
    'study_program_id': 101,
    'study_program_name': 'S1 Teknik Informatika',
    'department_name': 'Teknik Informatika',
  },
  {
    'study_program_id': 103,
    'study_program_name': 'D3 Teknik Informatika',
    'department_name': 'Teknik Informatika',
  },
  {
    'study_program_id': 201,
    'study_program_name': 'D4 Teknik Mesin',
    'department_name': 'Teknik Mesin',
  },
];

const List<Map<String, dynamic>> testRuangan = [
  {
    'id': 1,
    'kode_ruangan': 'RG-101',
    'name_ruangan': 'Workspace Virtual Reality',
    'kapasitas': 30,
    'name_gedung': 'Gedung A',
    'nomor_lantai': 2,
    'status_ruangan': 'tersedia',
    'fasilitas': ['Proyektor', 'AC', 'WiFi'],
    'deskripsi_ruangan': 'Ruang kolaborasi dengan perangkat VR.',
    'path_foto': null,
    'pic': 'Andi Wijaya',
  },
  {
    'id': 2,
    'kode_ruangan': 'RG-102',
    'name_ruangan': 'Ruang Seminar R.302',
    'kapasitas': 60,
    'name_gedung': 'Gedung B',
    'nomor_lantai': 3,
    'status_ruangan': 'tersedia',
    'fasilitas': ['Proyektor', 'Sound System', 'AC'],
    'deskripsi_ruangan': 'Ruang seminar kapasitas besar.',
    'path_foto': null,
    'pic': 'Andi Wijaya',
  },
  {
    'id': 3,
    'kode_ruangan': 'RG-103',
    'name_ruangan': 'Ruang Kelas A.101',
    'kapasitas': 40,
    'name_gedung': 'Gedung A',
    'nomor_lantai': 1,
    'status_ruangan': 'tersedia',
    'fasilitas': ['Proyektor', 'Whiteboard'],
    'deskripsi_ruangan': 'Ruang kelas reguler.',
    'path_foto': null,
    'pic': 'Andi Wijaya',
  },
  {
    'id': 4,
    'kode_ruangan': 'RG-104',
    'name_ruangan': 'Ruang Rapat B.201',
    'kapasitas': 20,
    'name_gedung': 'Gedung B',
    'nomor_lantai': 2,
    'status_ruangan': 'tersedia',
    'fasilitas': ['TV', 'AC', 'WiFi'],
    'deskripsi_ruangan': 'Ruang rapat kecil.',
    'path_foto': null,
    'pic': 'Andi Wijaya',
  },
];

const List<Map<String, dynamic>> testAlat = [
  {
    'id': 1,
    'kode_alat': 'AL01',
    'name_alat': 'Proyektor Epson 4K',
    'status_alat': 'tersedia',
    'deskripsi_alat': 'Proyektor resolusi tinggi.',
    'path_foto': null,
    'pic': 'Andi Wijaya',
  },
  {
    'id': 2,
    'kode_alat': 'AL02',
    'name_alat': 'Kamera Sony A6400',
    'status_alat': 'tersedia',
    'deskripsi_alat': 'Kamera mirrorless untuk dokumentasi.',
    'path_foto': null,
    'pic': 'Andi Wijaya',
  },
  {
    'id': 3,
    'kode_alat': 'AL03',
    'name_alat': 'Tripod Kamera',
    'status_alat': 'tersedia',
    'deskripsi_alat': 'Tripod kamera serbaguna.',
    'path_foto': null,
    'pic': 'Andi Wijaya',
  },
  {
    'id': 4,
    'kode_alat': 'AL04',
    'name_alat': 'Proyektor Epson EB-X06',
    'status_alat': 'tersedia',
    'deskripsi_alat': 'Proyektor portabel.',
    'path_foto': null,
    'pic': 'Andi Wijaya',
  },
];

const List<Map<String, dynamic>> testPenanggungJawab = [
  {'id_number': '19900001', 'name': 'Budi Santoso'},
  {'id_number': '19900003', 'name': 'Ahmad Rizal'},
];

const List<Map<String, dynamic>> testRiwayat = [
  {
    'id_peminjaman': 11,
    'id_alat': 2,
    'id_ruangan': null,
    'peminjam': 'Rajiv Tajusa David',
    'phone_peminjam': '081234567890',
    'name_kegiatan': 'Sesi foto dokumentasi',
    'jenis_kegiatan': 'Akademik',
    'hari_tanggal': '2026-10-10T00:00:00.000000Z',
    'tanggal_mulai': null,
    'tanggal_selesai': null,
    'jam_mulai': '08:00:00',
    'jam_selesai': '10:00:00',
    'keterangan': 'Dokumentasi kegiatan kampus',
    'alat': 'Kamera Sony A6400',
    'ruangan': null,
    'pic': 'Andi Wijaya',
    'phone_pic': '081234567891',
    'status_persetujuan': 'menunggu',
    'dibuat_pada': '2026-10-10T01:00:00.000000Z',
  },
  {
    'id_peminjaman': 10,
    'id_alat': null,
    'id_ruangan': 2,
    'peminjam': 'Rajiv Tajusa David',
    'phone_peminjam': '081234567890',
    'name_kegiatan': 'Seminar internal',
    'jenis_kegiatan': 'Akademik',
    'hari_tanggal': '2026-10-09T00:00:00.000000Z',
    'tanggal_mulai': null,
    'tanggal_selesai': null,
    'jam_mulai': '13:00:00',
    'jam_selesai': '15:00:00',
    'keterangan': 'Seminar himpunan mahasiswa',
    'alat': null,
    'ruangan': 'Ruang Seminar R.302',
    'pic': 'Andi Wijaya',
    'phone_pic': '081234567891',
    'status_persetujuan': 'disetujui',
    'dibuat_pada': '2026-10-09T02:00:00.000000Z',
  },
  {
    'id_peminjaman': 9,
    'id_alat': 4,
    'id_ruangan': null,
    'peminjam': 'Rajiv Tajusa David',
    'phone_peminjam': '081234567890',
    'name_kegiatan': 'Presentasi kelas',
    'jenis_kegiatan': 'Akademik',
    'hari_tanggal': '2026-10-08T00:00:00.000000Z',
    'tanggal_mulai': null,
    'tanggal_selesai': null,
    'jam_mulai': '09:00:00',
    'jam_selesai': '11:00:00',
    'keterangan': null,
    'alat': 'Proyektor Epson EB-X06',
    'ruangan': null,
    'pic': 'Andi Wijaya',
    'phone_pic': '081234567891',
    'status_persetujuan': 'menunggu',
    'dibuat_pada': '2026-10-08T03:00:00.000000Z',
  },
  {
    'id_peminjaman': 8,
    'id_alat': null,
    'id_ruangan': 1,
    'peminjam': 'Rajiv Tajusa David',
    'phone_peminjam': '081234567890',
    'name_kegiatan': 'Latihan VR',
    'jenis_kegiatan': 'Non-Akademik',
    'hari_tanggal': '2026-10-07T00:00:00.000000Z',
    'tanggal_mulai': null,
    'tanggal_selesai': null,
    'jam_mulai': '10:00:00',
    'jam_selesai': '12:00:00',
    'keterangan': null,
    'alat': null,
    'ruangan': 'Workspace Virtual Reality',
    'pic': 'Andi Wijaya',
    'phone_pic': '081234567891',
    'status_persetujuan': 'menunggu',
    'dibuat_pada': '2026-10-07T04:00:00.000000Z',
  },
  {
    'id_peminjaman': 7,
    'id_alat': 3,
    'id_ruangan': null,
    'peminjam': 'Rajiv Tajusa David',
    'phone_peminjam': '081234567890',
    'name_kegiatan': 'Perekaman video',
    'jenis_kegiatan': 'Non-Akademik',
    'hari_tanggal': '2026-10-06T00:00:00.000000Z',
    'tanggal_mulai': null,
    'tanggal_selesai': null,
    'jam_mulai': '14:00:00',
    'jam_selesai': '16:00:00',
    'keterangan': null,
    'alat': 'Tripod Kamera',
    'ruangan': null,
    'pic': 'Andi Wijaya',
    'phone_pic': '081234567891',
    'status_persetujuan': 'disetujui',
    'dibuat_pada': '2026-10-06T05:00:00.000000Z',
  },
  {
    'id_peminjaman': 6,
    'id_alat': 2,
    'id_ruangan': null,
    'peminjam': 'Rajiv Tajusa David',
    'phone_peminjam': '081234567890',
    'name_kegiatan': 'Dokumentasi lomba',
    'jenis_kegiatan': 'Non-Akademik',
    'hari_tanggal': '2026-10-05T00:00:00.000000Z',
    'tanggal_mulai': null,
    'tanggal_selesai': null,
    'jam_mulai': '08:00:00',
    'jam_selesai': '09:00:00',
    'keterangan': null,
    'alat': 'Kamera Canon EOS M50',
    'ruangan': null,
    'pic': 'Andi Wijaya',
    'phone_pic': '081234567891',
    'status_persetujuan': 'ditolak',
    'dibuat_pada': '2026-10-05T06:00:00.000000Z',
  },
];

http.Response _json(Object body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

Map<String, dynamic> _userWith(Map<String, dynamic> overrides) => {
  ...testUserJson,
  ...overrides,
};

/// Client HTTP palsu yang meniru response backend SPARA.
MockClient createMockClient() {
  return MockClient((request) async {
    final path = request.url.path;
    final method = request.method;

    Map<String, dynamic> body() {
      if (request.body.isEmpty) return const {};
      final decoded = jsonDecode(request.body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
    }

    if (method == 'POST' && path.endsWith('/login')) {
      final payload = body();
      if (payload['password'] != 'password') {
        return _json({'message': 'Kredensial tidak valid.'}, 401);
      }
      return _json({
        'access_token': 'test-token',
        'token_type': 'bearer',
        'user': testUserJson,
      });
    }

    if (method == 'POST' && path.endsWith('/register')) {
      return _json({'message': 'Registrasi berhasil.'}, 201);
    }

    if (method == 'POST' && path.endsWith('/logout')) {
      return _json({'message': 'Berhasil logout.'});
    }

    if (path.endsWith('/me')) {
      return _json({
        'data': {'user': testUserJson},
      });
    }

    if (method == 'POST' && path.endsWith('/update-profile-phone')) {
      final phone = '${body()['phone_number'] ?? testUserJson['phone_number']}';
      return _json({
        'message': 'Nomor telepon berhasil diperbarui.',
        'user': _userWith({'phone_number': phone}),
      });
    }

    if (method == 'POST' && path.endsWith('/update-password')) {
      return _json({'message': 'Kata sandi berhasil diperbarui.'});
    }

    if (method == 'POST' && path.endsWith('/update-profile-email')) {
      final email = '${body()['email'] ?? testUserJson['email']}';
      return _json({
        'message': 'Email berhasil diperbarui.',
        'user': _userWith({'email': email}),
      });
    }

    if (path.endsWith('/get-ruangan')) {
      return _json({'data': testRuangan});
    }

    if (path.endsWith('/get-alat')) {
      return _json({'data': testAlat});
    }

    if (path.endsWith('/get-program-studi')) {
      return _json({'data': testProgramStudi});
    }

    if (path.endsWith('/penanggung-jawab')) {
      return _json({'penanggung_jawab': testPenanggungJawab});
    }

    if (path.endsWith('/riwayat')) {
      return _json({
        'message': 'Riwayat peminjaman berhasil diambil.',
        'data': testRiwayat,
      });
    }

    if (method == 'POST' && path.contains('/peminjaman-batal/')) {
      return _json({'message': 'Peminjaman berhasil dibatalkan.'});
    }

    if (method == 'POST' && path.endsWith('/peminjaman')) {
      final payload = body();
      return _json({
        'message': 'Peminjaman berhasil diajukan.',
        'peminjaman': {
          'id_peminjaman': 99,
          'name_kegiatan': payload['name_kegiatan'],
          'status_persetujuan': 'menunggu',
        },
      }, 201);
    }

    return _json({'message': 'Endpoint tidak dikenal: $path'}, 404);
  });
}

/// Siapkan sesi login + client HTTP palsu sebelum widget di-pump.
Future<void> setUpTestApi() async {
  SharedPreferences.setMockInitialValues({});
  Session.instance.resetForTesting();
  ApiClient.instance.resetForTesting();
  ApiClient.instance.httpClient = createMockClient();
  await Session.instance.save(
    token: 'test-token',
    user: AppUser.fromJson(testUserJson),
  );
}

/// Bersihkan state global setelah test selesai.
void tearDownTestApi() {
  Session.instance.resetForTesting();
  ApiClient.instance.resetForTesting();
}
