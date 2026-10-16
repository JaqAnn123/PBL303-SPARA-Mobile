class Facility {
  final String id;
  final String name;
  final String category;
  final String imagePath;
  final String capacity;
  final String building;
  final String floor;
  final String type;

  const Facility({
    required this.id,
    required this.name,
    required this.category,
    required this.imagePath,
    required this.capacity,
    required this.building,
    required this.floor,
    required this.type,
  });
}

final List<Facility> dummyFacilities = [
  Facility(
    id: 'RU01',
    name: 'Workspace Virtual Reality',
    category: 'RUET01',
    imagePath: 'lib/assets/images/facility/room1.jpg',
    capacity: '10 Orang',
    building: 'Gedung Utama Lt.5',
    floor: 'Lantai 5',
    type: 'Ruangan',
  ),
  Facility(
    id: 'RU02',
    name: 'Workspace Virtual Reality',
    category: 'RUET02',
    imagePath: 'lib/assets/images/facility/room2.jpg',
    capacity: '20 Orang',
    building: 'Gedung Utama Lt.5',
    floor: 'Lantai 5',
    type: 'Ruangan',
  ),
  Facility(
    id: 'RU03',
    name: 'Workspace Virtual Reality',
    category: 'RUET03',
    imagePath: 'lib/assets/images/facility/room3.jpg',
    capacity: '15 Orang',
    building: 'Gedung Utama Lt.5',
    floor: 'Lantai 5',
    type: 'Ruangan',
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
  ),
];
