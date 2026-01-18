class BarcodeModel {
  final String id;
  final String nama_menu;
  final String code;

  BarcodeModel({
    required this.id,
    required this.nama_menu,
    required this.code
  });

  factory BarcodeModel.fromJson(Map data) {
    return BarcodeModel(
        id: data['_id'],
        nama_menu: data['nama_menu'],
        code: data['code']
    );
  }
}