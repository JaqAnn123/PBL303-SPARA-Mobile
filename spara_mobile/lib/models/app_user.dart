/// Data user yang login, sesuai response `POST /login` dan `GET /me`.
class AppUser {
  const AppUser({
    required this.idNumber,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.profilePicture,
    this.studyProgramId,
  });

  final String idNumber;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final String? profilePicture;
  final int? studyProgramId;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      idNumber: '${json['id_number'] ?? ''}',
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      phoneNumber: '${json['phone_number'] ?? ''}',
      role: '${json['role'] ?? 'mahasiswa'}',
      profilePicture: json['profile_picture'] as String?,
      studyProgramId: json['study_program_id'] == null
          ? null
          : int.tryParse('${json['study_program_id']}'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_number': idNumber,
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'role': role,
    'profile_picture': profilePicture,
    'study_program_id': studyProgramId,
  };

  AppUser copyWith({String? name, String? email, String? phoneNumber, String? profilePicture}) {
    return AppUser(
      idNumber: idNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role,
      profilePicture: profilePicture ?? this.profilePicture,
      studyProgramId: studyProgramId,
    );
  }

  /// Inisial nama untuk avatar, mis. "Rajiv Tajusa David" -> "RT".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'kepala':
        return 'Kepala SBUM';
      case 'pic':
        return 'PIC Fasilitas';
      case 'lecturer':
        return 'Dosen';
      default:
        return 'Mahasiswa';
    }
  }
}
