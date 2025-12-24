class StaffModel {
  final String id;
  final String nama_staff;
  final String email;
  final String jabatan;
  final String? foto_profile;

  StaffModel({
    required this.id,
    required this.nama_staff,
    required this.email,
    required this.jabatan,
    this.foto_profile,
  });

  factory StaffModel.fromJson(Map data) {
    return StaffModel(
      id: data['_id'] ?? '',
      nama_staff: data['nama_staff'] ?? '',
      email: data['email'] ?? '',
      jabatan: data['jabatan'] ?? '',
      foto_profile: data['foto_profile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nama_staff': nama_staff,
      'email': email,
      'jabatan': jabatan,
      'foto_profile': foto_profile,
    };
  }
}