//lib/model/staff.dart
class StaffModel {
  final String id;
  final String nama_staff;
  final String email;
  final String kata_sandi;
  final String jabatan;
  final String foto;
  final String? user_id; // Owner's Firebase user ID

  StaffModel({
    required this.id,
    required this.nama_staff,
    required this.email,
    required this.kata_sandi,
    required this.jabatan,
    required this.foto,
    this.user_id,
  });

  factory StaffModel.fromJson(Map<String, dynamic> data) {
    return StaffModel(
      id: data['_id'] ?? data['id'] ?? '',
      nama_staff: data['nama_staff'] ?? '',
      email: data['email'] ?? '',
      kata_sandi: data['kata_sandi'] ?? '',
      jabatan: data['jabatan'] ?? '',
      foto: data['foto'] ?? '',
      user_id: data['user_id'],
    );
  }
}