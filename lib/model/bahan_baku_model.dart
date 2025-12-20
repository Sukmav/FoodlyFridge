class BahanBakuModel {
  final String id;
  final String foto_bahan;
  final String nama_bahan;
  final String unit;
  final String gross_qty;
  final String harga_per_gross;
  final String harga_per_unit;
  final String stok_tersedia;
  final String stok_minimal;
  final String estimasi_umur;
  final String tanggal_masuk;
  final String tanggal_kadaluarsa;
  final String kategori;
  final String tempat_penyimpanan;
  final String catatan;

  BahanBakuModel({
    required this.id,
    required this.foto_bahan,
    required this.nama_bahan,
    required this.unit,
    required this.gross_qty,
    required this.harga_per_gross,
    required this.harga_per_unit,
    required this.stok_tersedia,
    required this.stok_minimal,
    required this.estimasi_umur,
    required this.tanggal_masuk,
    required this.tanggal_kadaluarsa,
    required this.kategori,
    required this.tempat_penyimpanan,
    required this.catatan
  });

  // Getter untuk kompatibilitas dengan code lain
  String get nama => nama_bahan;
  String get harga_unit => harga_per_unit;
  String get harga => harga_per_unit;

  factory BahanBakuModel.fromJson(Map<dynamic, dynamic> data) {
    return BahanBakuModel(
        id: data['_id']?.toString() ?? '',
        foto_bahan: data['foto_bahan']?.toString() ?? '',
        nama_bahan: data['nama_bahan']?.toString() ?? '',
        unit: data['unit']?.toString() ?? '',
        gross_qty: data['gross_qty']?.toString() ?? '',
        harga_per_gross: data['harga_per_gross']?.toString() ?? '',
        harga_per_unit: data['harga_per_unit']?.toString() ?? '',
        stok_tersedia: data['stok_tersedia']?.toString() ?? '',
        stok_minimal: data['stok_minimal']?.toString() ?? '',
        estimasi_umur: data['estimasi_umur']?.toString() ?? '',
        tanggal_masuk: data['tanggal_masuk']?.toString() ?? '',
        tanggal_kadaluarsa: data['tanggal_kadaluarsa']?.toString() ?? '',
        kategori: data['kategori']?.toString() ?? '',
        tempat_penyimpanan: data['tempat_penyimpanan']?.toString() ?? '',
        catatan: data['catatan']?.toString() ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foto_bahan': foto_bahan,
      'nama_bahan': nama_bahan,
      'unit': unit,
      'gross_qty': gross_qty,
      'harga_per_gross': harga_per_gross,
      'harga_per_unit': harga_per_unit,
      'stok_tersedia': stok_tersedia,
      'stok_minimal': stok_minimal,
      'estimasi_umur': estimasi_umur,
      'tanggal_masuk': tanggal_masuk,
      'tanggal_kadaluarsa': tanggal_kadaluarsa,
      'kategori': kategori,
      'tempat_penyimpanan': tempat_penyimpanan,
      'catatan': catatan,
    };
  }
}