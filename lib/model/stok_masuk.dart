class StokMasukModel {
  final String id;
  final String kode_bahan;
  final String tanggal_masuk;
  final String qty_pembelian;
  final String total_qty;
  final String harga_satuan;
  final String total_harga;
  final String nama_vendor;

  StokMasukModel({
    required this.id,
    required this.kode_bahan,
    required this.tanggal_masuk,
    required this.qty_pembelian,
    required this.total_qty,
    required this.harga_satuan,
    required this.total_harga,
    required this.nama_vendor
  });

  factory StokMasukModel.fromJson(Map data) {
    return StokMasukModel(
        id: data['_id'],
        kode_bahan: data['kode_bahan'],
        tanggal_masuk: data['tanggal_masuk'],
        qty_pembelian: data['qty_pembelian'],
        total_qty: data['total_qty'],
        harga_satuan: data['harga_satuan'],
        total_harga: data['total_harga'],
        nama_vendor: data['nama_vendor']
    );
  }
}

//stok masuk adalah fungsi yang akan digunakan oleh bagian gudang
// ketika ada pembelian bahan baku dari vendor, maka stok bahan baku akan bertambah
// sesuai dengan pembelian yang dilakukan dan dicatat pada stok masuk ini
// Stok masuk ini berisi informasi penting seperti kode bahan,