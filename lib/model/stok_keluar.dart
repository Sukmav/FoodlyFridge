//lib/model/stok_keluar.dart
class StokKeluarModel {
  final String id;
  final String invoice;
  final String nama_pemesanan;
  final String no_meja;
  final String tanggal;
  final String menu;
  final String? catatan;
  final String? total_harga;

  StokKeluarModel({
    required this.id,
    required this.invoice,
    required this.nama_pemesanan,
    required this.no_meja,
    required this.tanggal,
    required this.menu,
    this.catatan,
    this.total_harga,
  });

  factory StokKeluarModel.fromJson(Map data) {
    return StokKeluarModel(
        id: data['_id'],
        invoice: data['invoice'],
        nama_pemesanan: data['nama_pemesanan'],
        no_meja: data['no_meja'],
        tanggal: data['tanggal'],
        menu: data['menu'],
        catatan: data['catatan'],
        total_harga: data['total_harga'],
    );
  }
}

//stok kluar
// stok keluar ini, adalah fungsi yang akan digunakan oleh kasir, yang dimana
// ketika ada pemesanan dari pelanggan, maka stok bahan baku akan berkurang sesuai dengan menu yang dipesan
// dan dicatat pada stok keluar ini. Stok keluar ini berisi informasi penting seperti invoice,
// nama pemesanan, nomor meja, tanggal pemesanan, dan menu yang dipesan.
// Dengan adanya pencatatan stok keluar ini, restoran dapat memantau dan mengelola persediaan bahan baku mereka dengan lebih efektif,
// serta mengidentifikasi tren pemesanan yang dapat membantu dalam perencanaan pembelian bahan baku di masa depan.
// Hal ini membantu restoran dalam mengoptimalkan penggunaan bahan baku, mengurangi pemborosan, dan meningkatkan efisiensi operasional secara keseluruhan.
// Selain itu, data stok keluar juga dapat digunakan untuk analisis penjualan dan perencanaan menu,
// yang pada akhirnya dapat meningkatkan profitabilitas bisnis restoran.
// Dengan demikian, stok keluar model ini menjadi alat penting dalam manajemen operasional restoran.