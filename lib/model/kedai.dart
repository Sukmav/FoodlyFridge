//lib/model/kedai.dart
class KedaiModel {
  final String id;
  final String logo_kedai;
  final String nama_kedai;
  final String alamat_kedai;
  final String nomor_telepon;
  final String catatan_struk;

  KedaiModel({
    required this.id,
    required this.logo_kedai,
    required this.nama_kedai,
    required this.alamat_kedai,
    required this.nomor_telepon,
    required this.catatan_struk
  });

  // Factory constructor from GoCloud response
  factory KedaiModel.fromJson(Map<String, dynamic> data, String docId) {
    return KedaiModel(
        id: docId,
        logo_kedai: data['logo_kedai'] ?? '',
        nama_kedai: data['nama_kedai'] ?? '',
        alamat_kedai: data['alamat_kedai'] ?? '',
        nomor_telepon: data['nomor_telepon'] ?? '',
        catatan_struk: data['catatan_struk'] ?? ''
    );
  }

  // Convert to Map for GoCloud (tidak perlu FieldValue.serverTimestamp)
  Map<String, dynamic> toJson() {
    return {
      'logo_kedai': logo_kedai,
      'nama_kedai': nama_kedai,
      'alamat_kedai': alamat_kedai,
      'nomor_telepon': nomor_telepon,
      'catatan_struk': catatan_struk,
    };
  }

  // Convert to Map for update
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'logo_kedai': logo_kedai,
      'nama_kedai': nama_kedai,
      'alamat_kedai': alamat_kedai,
      'nomor_telepon': nomor_telepon,
      'catatan_struk': catatan_struk,
    };
  }
}
