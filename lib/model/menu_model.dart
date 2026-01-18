//lib/model/menu_model.dart
class MenuModel {
  final String id;
  final String kode_menu;
  final String nama_menu;
  final String kategori;
  final String harga;
  final String stok;
  final List<BahanBakuItem> bahan_baku;
  final String foto_menu;
  final String barcode;

  MenuModel({
    required this.id,
    required this.kode_menu,
    required this.nama_menu,
    required this.kategori,
    required this.harga,
    required this.stok,
    required this.bahan_baku,
    required this.foto_menu,
    required this.barcode,
  });

  factory MenuModel.fromJson(Map<dynamic, dynamic> data) {
    List<BahanBakuItem> bahanBakuList = [];
    if (data['bahan_baku'] != null) {
      if (data['bahan_baku'] is List) {
        bahanBakuList = (data['bahan_baku'] as List)
            .map((item) => BahanBakuItem.fromJson(item))
            .toList();
      }
    }

    return MenuModel(
      id: data['_id']?.toString() ?? '',
      kode_menu: data['kode_menu']?.toString() ?? '',
      nama_menu: data['nama_menu']?.toString() ?? '',
      kategori: data['kategori']?.toString() ?? '',
      harga: data['harga']?.toString() ?? '',
      stok: data['stok']?.toString() ?? '',
      bahan_baku: bahanBakuList,
      foto_menu: data['foto_menu']?.toString() ?? '',
      barcode: data['barcode']?.toString() ?? data['kode_menu']?.toString() ?? '', // Generate barcode dari kode_menu jika tidak ada
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kode_menu': kode_menu,
      'nama_menu': nama_menu,
      'kategori': kategori,
      'harga': harga,
      'stok': stok,
      'bahan_baku': bahan_baku.map((item) => item.toJson()).toList(),
      'foto_menu': foto_menu,
      'barcode': barcode,
    };
  }
}

class BahanBakuItem {
  final String id_bahan;
  final String nama_bahan;
  final String jumlah;
  final String unit;

  BahanBakuItem({
    required this.id_bahan,
    required this.nama_bahan,
    required this.jumlah,
    required this.unit,
  });

  factory BahanBakuItem.fromJson(Map<dynamic, dynamic> data) {
    return BahanBakuItem(
      id_bahan: data['id_bahan']?.toString() ?? '',
      nama_bahan: data['nama_bahan']?.toString() ?? '',
      jumlah: data['jumlah']?.toString() ?? '',
      unit: data['unit']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_bahan': id_bahan,
      'nama_bahan': nama_bahan,
      'jumlah': jumlah,
      'unit': unit,
    };
  }
}
