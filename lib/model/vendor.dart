class VendorModel {
  final String id;
  final String nama_vendor;
  final String nama_pic;
  final String nomor_tlp;
  final String alamat;
  final String bahan_baku;
  final String catatan;

  VendorModel({
    required this.id,
    required this.nama_vendor,
    required this.nama_pic,
    required this.nomor_tlp,
    required this.alamat,
    required this.bahan_baku,
    required this.catatan
  });

  factory VendorModel.fromJson(Map data) {
    return VendorModel(
        id: data['_id'] ?? '',
        nama_vendor: data['nama_vendor'] ?? '',
        nama_pic: data['nama_pic'] ?? '',
        nomor_tlp: data['nomor_tlp'] ?? '',
        alamat: data['alamat'] ?? '',
        bahan_baku: data['bahan_baku'] ?? '',
        catatan: data['catatan'] ?? ''
    );
  }
}

//vendor ini adalah fungsi yang akan digunakan oleh bagian gudang
// untuk mencatat informasi tentang pemasok bahan baku restoran seperti nama vendor,
// nama person in charge (PIC), nomor telepon, alamat, jenis bahan baku yang