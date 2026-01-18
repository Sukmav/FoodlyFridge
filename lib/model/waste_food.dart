//lib/model/waste_food.dart
class WasteFoodModel {
  final String id;
  final String nama_bahan;
  final String jenis_waste;
  final String jumlah_terbuang;
  final String tanggal;
  final String catatan;
  final String foto;
  final String total_kerugian;
  final String kode_bahan;
  final String user_id;

  WasteFoodModel({
    required this.id,
    required this.nama_bahan,
    required this.jenis_waste,
    required this.jumlah_terbuang,
    required this.tanggal,
    required this.catatan,
    required this.foto,
    required this.total_kerugian,
    required this.kode_bahan,
    required this.user_id,
  });

  factory WasteFoodModel.fromJson(Map<String, dynamic> json) {
    return WasteFoodModel(
      id: json['id']?.toString() ?? '',
      nama_bahan: json['nama_bahan']?.toString() ?? '',
      jenis_waste: json['jenis_waste']?.toString() ?? '',
      jumlah_terbuang: json['jumlah_terbuang']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      catatan: json['catatan']?.toString() ?? '',
      foto: json['foto']?.toString() ?? '',
      total_kerugian: json['total_kerugian']?.toString() ?? '',
      kode_bahan: json['kode_bahan']?.toString() ?? '',
      user_id: json['user_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_bahan': nama_bahan,
      'jenis_waste': jenis_waste,
      'jumlah_terbuang': jumlah_terbuang,
      'tanggal': tanggal,
      'catatan': catatan,
      'foto': foto,
      'total_kerugian': total_kerugian,
      'kode_bahan': kode_bahan,
      'user_id': user_id,
    };
  }
}
