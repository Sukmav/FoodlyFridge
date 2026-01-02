class StrukModel {
  final String id;
  final String kode_struk;
  final String tanggal;
  final String nama_kasir;
  final String pembayaran;
  final String menu;
  final String total;

  StrukModel({
    required this.id,
    required this.kode_struk,
    required this.tanggal,
    required this.nama_kasir,
    required this.pembayaran,
    required this.menu,
    required this.total
  });

  factory StrukModel.fromJson(Map data) {
    return StrukModel(
        id: data['_id'],
        kode_struk: data['kode_struk'],
        tanggal: data['tanggal'],
        nama_kasir: data['nama_kasir'],
        pembayaran: data['pembayaran'],
        menu: data['menu'],
        total: data['total']
    );
  }
}

//struk ini adalah fungsi yang akan digunakan untuk mencatat setiap transaksi penjualan yang terjadi di restoran terutama pada role kasir. Struk ini berisi informasi penting seperti kode struk, tanggal transaksi, nama kasir yang melayani, metode pembayaran yang digunakan, daftar menu yang dipesan, dan total pembayaran. Dengan adanya struk ini, restoran dapat dengan mudah melacak dan mengelola transaksi penjualan mereka.