class MenuModel {
  final String id;
  final String id_menu;
  final String nama_menu;
  final String foto_menu;
  final String kategori;
  final String harga_jual;
  final String barcode;
  final String bahan;
  final String jumlah;
  final String satuan;
  final String biaya;
  final String catatan;

  MenuModel({
    required this.id,
    required this.id_menu,
    required this.nama_menu,
    required this.foto_menu,
    required this.kategori,
    required this.harga_jual,
    required this.barcode,
    required this.bahan,
    required this.jumlah,
    required this.satuan,
    required this.biaya,
    required this.catatan
  });

  factory MenuModel.fromJson(Map data) {
    return MenuModel(
        id: data['_id'] ?? '',
        id_menu: data['id_menu'] ?? '',
        nama_menu: data['nama_menu'] ?? '',
        foto_menu: data['foto_menu'] ?? '',
        kategori: data['kategori'] ?? '',
        harga_jual: data['harga_jual'] ?? '',
        barcode: data['barcode'] ?? '',
        bahan: data['bahan'] ?? '',
        jumlah: data['jumlah'] ?? '',
        satuan: data['satuan'] ?? '',
        biaya: data['biaya'] ?? '',
        catatan: data['catatan'] ?? ''
    );
  }
}