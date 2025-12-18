// ignore_for_file: prefer_interpolation_to_compose_strings, non_constant_identifier_names

import 'package:http/http.dart' as http;
import 'dart:typed_data';

class DataService {
  Future insertMenu(String appid, String id_menu, String nama_menu, String foto_menu, String kategori, String harga_jual, String barcode, String bahan, String jumlah, String satuan, String biaya, String catatan) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(Uri.parse(uri), body: {
        'token': '68d7486b1f753691225cdf8d',
        'project': 'foodlydfridge',
        'collection': 'menu',
        'appid': appid,
        'id_menu': id_menu,
        'nama_menu': nama_menu,
        'foto_menu': foto_menu,
        'kategori': kategori,
        'harga_jual': harga_jual,
        'barcode': barcode,
        'bahan': bahan,
        'jumlah': jumlah,
        'satuan': satuan,
        'biaya': biaya,
        'catatan': catatan
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertBahanBaku(String appid, String foto_bahan, String nama_bahan, String unit, String gross_qty, String harga_per_gross, String harga_per_unit, String stok_tersedia, String estimasi_umur, String tanggal_masuk, String tanggal_kadaluarsa, String kategori, String tempat_penyimpanan, String catatan) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(Uri.parse(uri), body: {
        'token': '68d7486b1f753691225cdf8d',
        'project': 'foodlydfridge',
        'collection': 'bahan_baku',
        'appid': appid,
        'foto_bahan': foto_bahan,
        'nama_bahan': nama_bahan,
        'unit': unit,
        'gross_qty': gross_qty,
        'harga_per_gross': harga_per_gross,
        'harga_per_unit': harga_per_unit,
        'stok_tersedia': stok_tersedia,
        'estimasi_umur': estimasi_umur,
        'tanggal_masuk': tanggal_masuk,
        'tanggal_kadaluarsa': tanggal_kadaluarsa,
        'kategori': kategori,
        'tempat_penyimpanan': tempat_penyimpanan,
        'catatan': catatan
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertBarcode(String appid, String nama_menu, String code) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(Uri.parse(uri), body: {
        'token': '68d7486b1f753691225cdf8d',
        'project': 'foodlydfridge',
        'collection': 'barcode',
        'appid': appid,
        'nama_menu': nama_menu,
        'code': code
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertVendor(String appid, String nama_vendor, String nama_pic, String nomor_tlp, String alamat, String bahan_baku, String catatan) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(Uri.parse(uri), body: {
        'token': '68d7486b1f753691225cdf8d',
        'project': 'foodlydfridge',
        'collection': 'vendor',
        'appid': appid,
        'nama_vendor': nama_vendor,
        'nama_pic': nama_pic,
        'nomor_tlp': nomor_tlp,
        'alamat': alamat,
        'bahan_baku': bahan_baku,
        'catatan': catatan
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertWasteFood(String appid, String nama_bahan, String jenis_waste, String jumlah_terbuang, String tanggal, String catatan, String foto) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(Uri.parse(uri), body: {
        'token': '68d7486b1f753691225cdf8d',
        'project': 'foodlydfridge',
        'collection': 'waste_food',
        'appid': appid,
        'nama_bahan': nama_bahan,
        'jenis_waste': jenis_waste,
        'jumlah_terbuang': jumlah_terbuang,
        'tanggal': tanggal,
        'catatan': catatan,
        'foto': foto
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertStaff(String appid, String nama_staff, String nomor_telepone) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(Uri.parse(uri), body: {
        'token': '68d7486b1f753691225cdf8d',
        'project': 'foodlydfridge',
        'collection': 'staff',
        'appid': appid,
        'nama_staff': nama_staff,
        'nomor_telepone': nomor_telepone
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertStokMasuk(String appid, String kode_bahan, String tanggal_masuk, String qty_pembelian, String total_qty, String harga_satuan, String total_harga, String vendor_id) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(Uri.parse(uri), body: {
        'token': '68d7486b1f753691225cdf8d',
        'project': 'foodlydfridge',
        'collection': 'stok_masuk',
        'appid': appid,
        'kode_bahan': kode_bahan,
        'tanggal_masuk': tanggal_masuk,
        'qty_pembelian': qty_pembelian,
        'total_qty': total_qty,
        'harga_satuan': harga_satuan,
        'total_harga': total_harga,
        'vendor_id': vendor_id
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertStruk(String appid, String kode_struk, String tanggal, String nama_kasir, String pembayaran, String menu, String total) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(Uri.parse(uri), body: {
        'token': '68d7486b1f753691225cdf8d',
        'project': 'foodlydfridge',
        'collection': 'struk',
        'appid': appid,
        'kode_struk': kode_struk,
        'tanggal': tanggal,
        'nama_kasir': nama_kasir,
        'pembayaran': pembayaran,
        'menu': menu,
        'total': total
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertKedai(String appid, String logo_kedai, String nama_kedai, String alamat_kedai, String nomor_telepon, String catatan_struk) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(Uri.parse(uri), body: {
        'token': '68d7486b1f753691225cdf8d',
        'project': 'foodlydfridge',
        'collection': 'kedai',
        'appid': appid,
        'logo_kedai': logo_kedai,
        'nama_kedai': nama_kedai,
        'alamat_kedai': alamat_kedai,
        'nomor_telepon': nomor_telepon,
        'catatan_struk': catatan_struk
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertStokKeluar(String appid, String invoice, String nama_pemesanan, String no_meja, String tanggal) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(Uri.parse(uri), body: {
        'token': '68d7486b1f753691225cdf8d',
        'project': 'foodlydfridge',
        'collection': 'stok_keluar',
        'appid': appid,
        'invoice': invoice,
        'nama_pemesanan': nama_pemesanan,
        'no_meja': no_meja,
        'tanggal': tanggal
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectAll(String token, String project, String collection, String appid) async {
    String uri = 'https://api.247go.app/v5/select_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectId(String token, String project, String collection, String appid, String id) async {
    String uri = 'https://api.247go.app/v5/select_id/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/id/' + id;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
    String uri = 'https://api.247go.app/v5/select_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
    String uri = 'https://api.247go.app/v5/select_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
    String uri = 'https://api.247go.app/v5/select_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
    String uri = 'https://api.247go.app/v5/select_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
    String uri = 'https://api.247go.app/v5/select_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future removeAll(String token, String project, String collection, String appid) async {
    String uri = 'https://api.247go.app/v5/remove_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeId(String token, String project, String collection, String appid, String id) async {
    String uri = 'https://api.247go.app/v5/remove_id/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/id/' + id;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
    String uri = 'https://api.247go.app/v5/remove_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
    String uri = 'https://api.247go.app/v5/remove_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
    String uri = 'https://api.247go.app/v5/remove_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
    String uri = 'https://api.247go.app/v5/remove_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
    String uri = 'https://api.247go.app/v5/remove_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future updateAll(String update_field, String update_value, String token, String project, String collection, String appid) async {
    String uri = 'https://api.247go.app/v5/update_all/';

    try {
      final response = await http.put(Uri.parse(uri),body: {
        'update_field': update_field,
        'update_value': update_value,
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateId(String update_field, String update_value, String token, String project, String collection, String appid, String id) async {
    String uri = 'https://api.247go.app/v5/update_id/';

    try {
      final response = await http.put(Uri.parse(uri),body: {
        'update_field': update_field,
        'update_value': update_value,
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid,
        'id': id
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhere(String where_field, String where_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
    String uri = 'https://api.247go.app/v5/update_where/';

    try {
      final response = await http.put(Uri.parse(uri),body: {
        'where_field': where_field,
        'where_value': where_value,
        'update_field': update_field,
        'update_value': update_value,
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateOrWhere(String or_where_field, String or_where_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
    String uri = 'https://api.247go.app/v5/update_or_where/';

    try {
      final response = await http.put(Uri.parse(uri),body: {
        'or_where_field': or_where_field,
        'or_where_value': or_where_value,
        'update_field': update_field,
        'update_value': update_value,
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhereLike(String wlike_field, String wlike_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
    String uri = 'https://api.247go.app/v5/update_where_like/';

    try {
      final response = await http.put(Uri.parse(uri),body: {
        'wlike_field': wlike_field,
        'wlike_value': wlike_value,
        'update_field': update_field,
        'update_value': update_value,
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhereIn(String win_field, String win_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
    String uri = 'https://api.247go.app/v5/update_where_in/';

    try {
      final response = await http.put(Uri.parse(uri),body: {
        'win_field': win_field,
        'win_value': win_value,
        'update_field': update_field,
        'update_value': update_value,
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhereNotIn(String wnotin_field, String wnotin_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
    String uri = 'https://api.247go.app/v5/update_where_not_in/';

    try {
      final response = await http.put(Uri.parse(uri),body: {
        'wnotin_field': wnotin_field,
        'wnotin_value': wnotin_value,
        'update_field': update_field,
        'update_value': update_value,
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future firstAll(String token, String project, String collection, String appid) async {
    String uri = 'https://api.247go.app/v5/first_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
    String uri = 'https://api.247go.app/v5/first_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
    String uri = 'https://api.247go.app/v5/first_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
    String uri = 'https://api.247go.app/v5/first_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
    String uri = 'https://api.247go.app/v5/first_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
    String uri = 'https://api.247go.app/v5/first_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastAll(String token, String project, String collection, String appid) async {
    String uri = 'https://api.247go.app/v5/last_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
    String uri = 'https://api.247go.app/v5/last_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
    String uri = 'https://api.247go.app/v5/last_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
    String uri = 'https://api.247go.app/v5/last_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
    String uri = 'https://api.247go.app/v5/last_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
    String uri = 'https://api.247go.app/v5/last_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomAll(String token, String project, String collection, String appid) async {
    String uri = 'https://api.247go.app/v5/random_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
    String uri = 'https://api.247go.app/v5/random_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
    String uri = 'https://api.247go.app/v5/random_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
    String uri = 'https://api.247go.app/v5/random_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
    String uri = 'https://api.247go.app/v5/random_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
    String uri = 'https://api.247go.app/v5/random_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future upload(
      String token,
      String project,
      Uint8List fileBytes,
      String extension) async {
    String uri = 'https://api.247go.app/v5/upload/';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(uri));

      request.fields['token'] = token;
      request.fields['project'] = project;

      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: 'file.$extension',
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        return '{"error": "Upload failed"}';
      }
    } catch (e) {
      return '{"error": "Upload failed"}';
    }
  }
}