class BahanBakuModel {
  final String id;
  final String foto_bahan;
  final String nama_bahan;
  final String unit;
  final String gross_qty;
  final String harga_per_gross;
  final String harga_per_unit;
  final String stok_tersedia;
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
    required this.estimasi_umur,
    required this.tanggal_masuk,
    required this.tanggal_kadaluarsa,
    required this.kategori,
    required this.tempat_penyimpanan,
    required this.catatan
  });

  factory BahanBakuModel.fromJson(Map data) {
    return BahanBakuModel(
        id: data['_id'],
        foto_bahan: data['foto_bahan'],
        nama_bahan: data['nama_bahan'],
        unit: data['unit'],
        gross_qty: data['gross_qty'],
        harga_per_gross: data['harga_per_gross'],
        harga_per_unit: data['harga_per_unit'],
        stok_tersedia: data['stok_tersedia'],
        estimasi_umur: data['estimasi_umur'],
        tanggal_masuk: data['tanggal_masuk'],
        tanggal_kadaluarsa: data['tanggal_kadaluarsa'],
        kategori: data['kategori'],
        tempat_penyimpanan: data['tempat_penyimpanan'],
        catatan: data['catatan']
    );
  }
}