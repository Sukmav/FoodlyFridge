class StokKeluarModel {
  final String id;
  final String invoice;
  final String nama_pemesanan;
  final String no_meja;
  final String tanggal;

  StokKeluarModel({
    required this.id,
    required this.invoice,
    required this.nama_pemesanan,
    required this.no_meja,
    required this.tanggal
  });

  factory StokKeluarModel.fromJson(Map data) {
    return StokKeluarModel(
        id: data['_id'],
        invoice: data['invoice'],
        nama_pemesanan: data['nama_pemesanan'],
        no_meja: data['no_meja'],
        tanggal: data['tanggal']
    );
  }
}