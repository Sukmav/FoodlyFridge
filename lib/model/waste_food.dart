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

  WasteFoodModel({
    required this.id,
    required this.nama_bahan,
    required this.jenis_waste,
    required this.jumlah_terbuang,
    required this.tanggal,
    required this.catatan,
    required this.foto,
    required this.total_kerugian,
    required this.kode_bahan
  });

  factory WasteFoodModel.fromJson(Map data) {
    return WasteFoodModel(
        id: data['_id'],
        nama_bahan: data['nama_bahan'],
        jenis_waste: data['jenis_waste'],
        jumlah_terbuang: data['jumlah_terbuang'],
        tanggal: data['tanggal'],
        catatan: data['catatan'],
        foto: data['foto'],
        total_kerugian: data['total_kerugian'],
        kode_bahan: data['kode_bahan']
    );
  }
}