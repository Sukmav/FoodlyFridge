class WasteFoodModel {
  final String id;
  final String nama_bahan;
  final String jenis_waste;
  final String jumlah_terbuang;
  final String tanggal;
  final String catatan;
  final String foto;

  WasteFoodModel({
    required this.id,
    required this.nama_bahan,
    required this.jenis_waste,
    required this.jumlah_terbuang,
    required this.tanggal,
    required this.catatan,
    required this.foto
  });

  factory WasteFoodModel.fromJson(Map data) {
    return WasteFoodModel(
        id: data['_id'],
        nama_bahan: data['nama_bahan'],
        jenis_waste: data['jenis_waste'],
        jumlah_terbuang: data['jumlah_terbuang'],
        tanggal: data['tanggal'],
        catatan: data['catatan'],
        foto: data['foto']
    );
  }
}