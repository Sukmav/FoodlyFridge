class StokKeluarModel {
  final String id;
  final String invoice;
  final String nama_pemesanan;
  final String no_meja;
  final String tanggal;
  final String menu;

  StokKeluarModel({
    required this.id,
    required this.invoice,
    required this.nama_pemesanan,
    required this.no_meja,
    required this.tanggal,
    required this.menu
  });

  factory StokKeluarModel.fromJson(Map data) {
    return StokKeluarModel(
        id: data['_id'],
        invoice: data['invoice'],
        nama_pemesanan: data['nama_pemesanan'],
        no_meja: data['no_meja'],
        tanggal: data['tanggal'],
        menu: data['menu']
    );
  }
}