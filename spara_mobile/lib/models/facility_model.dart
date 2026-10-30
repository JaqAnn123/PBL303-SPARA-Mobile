class Facility {
  final String id;
  final String name;
  final String category;
  final String imagePath;
  final String capacity;
  final String building;
  final String floor;
  final String type;
  final String status;

  /// ID numerik dari database (dipakai saat mengirim pengajuan peminjaman).
  final int? dbId;

  /// URL foto dari backend (`path_foto`).
  final String? imageUrl;

  /// Daftar fasilitas (khusus ruangan).
  final List<String> facilities;

  /// Deskripsi singkat dari backend.
  final String? description;

  /// Nama penanggung jawab.
  final String? pic;

  const Facility({
    required this.id,
    required this.name,
    required this.category,
    required this.imagePath,
    required this.capacity,
    required this.building,
    required this.floor,
    required this.type,
    this.status = 'Tersedia',
    this.dbId,
    this.imageUrl,
    this.facilities = const [],
    this.description,
    this.pic,
  });

  static String _statusRuangan(String? value) {
    switch (value) {
      case 'maintenance':
        return 'Maintenance';
      case 'tidak_tersedia':
        return 'Dipinjam';
      default:
        return 'Tersedia';
    }
  }

  static String _statusAlat(String? value) {
    switch (value) {
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Tersedia';
    }
  }

  factory Facility.fromRuangan(Map<String, dynamic> json) {
    final id = int.tryParse('${json['id']}') ?? 0;
    return Facility(
      id: '${json['kode_ruangan'] ?? 'RU-$id'}',
      dbId: id,
      name: '${json['name_ruangan'] ?? 'Ruangan'}',
      category: '${json['kode_ruangan'] ?? ''}',
      imagePath: 'lib/assets/images/facility/room1.jpg',
      imageUrl: json['path_foto'] as String?,
      capacity: '${json['kapasitas'] ?? '-'} Orang',
      building: '${json['name_gedung'] ?? '-'}',
      floor: 'Lantai ${json['nomor_lantai'] ?? '-'}',
      type: 'Ruangan',
      status: _statusRuangan(json['status_ruangan'] as String?),
      facilities: (json['fasilitas'] as List? ?? const [])
          .map((e) => '$e')
          .toList(),
      description: json['deskripsi_ruangan'] as String?,
      pic: json['pic'] as String?,
    );
  }

  factory Facility.fromAlat(Map<String, dynamic> json) {
    final id = int.tryParse('${json['id']}') ?? 0;
    return Facility(
      id: '${json['kode_alat'] ?? 'AL-$id'}',
      dbId: id,
      name: '${json['name_alat'] ?? 'Peralatan'}',
      category: '${json['kode_alat'] ?? ''}',
      imagePath: 'lib/assets/images/facility/tool1.jpg',
      imageUrl: json['path_foto'] as String?,
      capacity: '1 Unit',
      building: 'Gudang Inventaris',
      floor: '-',
      type: 'Peralatan',
      status: _statusAlat(json['status_alat'] as String?),
      description: json['deskripsi_alat'] as String?,
      pic: json['pic'] as String?,
    );
  }
}

final List<Facility> dummyFacilities = [
  Facility(
    id: 'RU01',
    name: 'Ruang Kelas A101',
    category: 'RUET01',
    imagePath: 'lib/assets/images/facility/room1.jpg',
    capacity: '40 Orang',
    building: 'Gedung A',
    floor: 'Lantai 1',
    type: 'Ruangan',
    status: 'Tersedia',
  ),
  Facility(
    id: 'RU02',
    name: 'Ruang Kelas A102',
    category: 'RUET02',
    imagePath: 'lib/assets/images/facility/room2.jpg',
    capacity: '40 Orang',
    building: 'Gedung A',
    floor: 'Lantai 1',
    type: 'Ruangan',
    status: 'Dipinjam',
  ),
  Facility(
    id: 'RU03',
    name: 'Workspace Virtual Reality',
    category: 'RUET03',
    imagePath: 'lib/assets/images/facility/room3.jpg',
    capacity: '15 Orang',
    building: 'Gedung Utama',
    floor: 'Lantai 5',
    type: 'Ruangan',
    status: 'Tersedia',
  ),
  Facility(
    id: 'AL01',
    name: 'Proyektor Epson 4K',
    category: 'ALIN01',
    imagePath: 'lib/assets/images/facility/projector.jpg',
    capacity: '1 Unit',
    building: 'Gedung B',
    floor: 'Lantai 2',
    type: 'Peralatan',
    status: 'Tersedia',
  ),
  Facility(
    id: 'AL02',
    name: 'Laptop MacBook Pro',
    category: 'ALIN02',
    imagePath: 'lib/assets/images/facility/laptop.jpg',
    capacity: '1 Unit',
    building: 'Gedung A',
    floor: 'Lantai 1',
    type: 'Peralatan',
    status: 'Maintenance',
  ),
];
