// helpers/simple_riwayat_service.dart - VERSI DIPERBAIKI
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleRiwayatService {
  static const String _token = '68d7486b1f753691225cdf8d';
  static const String _project = 'foodlydfridge';
  static const String _baseUrl = 'https://api.247go.app/v5';

  // Helper untuk handle CORS di web
  static String _getUrl(String endpoint) {
    if (kIsWeb) {
      // Gunakan CORS proxy untuk web
      return 'https://corsproxy.io/?${Uri.encodeFull('https://api.247go.app/v5/$endpoint')}';
    } else {
      return 'https://api.247go.app/v5/$endpoint';
    }
  }

  // Helper method untuk format currency
  static String _formatCurrency(dynamic value) {
    try {
      final number = double.tryParse(value.toString()) ?? 0;
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(number);
    } catch (e) {
      return 'Rp 0';
    }
  }

  // TAMBAHKAN: Method khusus untuk mengambil waste_food berdasarkan user_id
  Future<List<Map<String, dynamic>>> getWasteFoodByUserId(String userId) async {
    try {
      if (kDebugMode) {
        print('🔄 Fetching waste_food for user: $userId');
      }

      final response = await http.post(
        Uri.parse(_getUrl('select/')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'token': _token,
          'project': _project,
          'collection': 'waste_food',
          'appid': '', // Kosongkan jika tidak perlu
          'user_id': userId, // Filter berdasarkan user_id
        },
      );

      if (kDebugMode) {
        print('📊 Waste Food Response: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final data = json.decode(response.body);
          List<dynamic> items = [];

          if (data is List) {
            items = data;
          } else if (data is Map) {
            items = [data];
          }

          if (kDebugMode) {
            print('✅ Found ${items.length} waste food items for user: $userId');
          }

          // Konversi ke format yang diinginkan
          return items.map((item) {
            final Map<String, dynamic> wasteData = Map<String, dynamic>.from(
              item,
            );

            return {
              'id': wasteData['_id']?.toString() ?? '',
              'type': 'waste_food',
              'action': 'create',
              'title': 'Waste Food: ${wasteData['nama_bahan'] ?? 'Bahan'}',
              'description':
              'Jenis: ${wasteData['jenis_waste'] ?? ''} - Jumlah: ${wasteData['jumlah_terbuang'] ?? ''} ${wasteData['unit'] ?? 'gr'} | Kerugian: ${_formatCurrency(wasteData['total_kerugian'] ?? '0')}',
              'user_name': wasteData['user_name'] ?? 'User',
              'user_id': wasteData['user_id'] ?? userId,
              'timestamp':
              wasteData['tanggal'] ?? DateTime.now().toIso8601String(),
              'jumlah':
              double.tryParse(
                wasteData['jumlah_terbuang']?.toString() ?? '0',
              ) ??
                  0,
              'kerugian':
              double.tryParse(
                wasteData['total_kerugian']?.toString() ?? '0',
              ) ??
                  0,
              'color': '#f83600',
              'icon': 'delete',
            };
          }).toList();
        } catch (e) {
          if (kDebugMode) print('❌ Error parsing waste_food: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('❌ Error in getWasteFoodByUserId: $e');
      return [];
    }
  }

  // TAMBAHKAN: Method khusus untuk stok_keluar
  Future<List<Map<String, dynamic>>> getStokKeluarByUserId(
      String userId,
      ) async {
    try {
      final response = await http.post(
        Uri.parse(_getUrl('select/')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'token': _token,
          'project': _project,
          'collection': 'stok_keluar',
          'appid': '',
          'user_id': userId,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final data = json.decode(response.body);
          List<dynamic> items = [];

          if (data is List) {
            items = data;
          } else if (data is Map) {
            items = [data];
          }

          return items.map((item) {
            final Map<String, dynamic> stokData = Map<String, dynamic>.from(
              item,
            );

            return {
              'id': stokData['_id']?.toString() ?? '',
              'type': 'stok_keluar',
              'action': 'create',
              'title': 'Stok Keluar: ${stokData['invoice'] ?? 'Transaksi'}',
              'description':
              'Invoice: ${stokData['invoice'] ?? ''} - Total: ${_formatCurrency(stokData['total_harga'] ?? '0')}',
              'user_name': stokData['nama_kasir'] ?? 'Kasir',
              'user_id': stokData['user_id'] ?? userId,
              'timestamp':
              stokData['tanggal'] ?? DateTime.now().toIso8601String(),
              'total':
              double.tryParse(stokData['total_harga']?.toString() ?? '0') ??
                  0,
              'color': '#f093fb',
              'icon': 'upload',
            };
          }).toList();
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStokMasukByUserId(String userId) async {
    try {
      final response = await http.post(
        Uri.parse(_getUrl('select/')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'token': _token,
          'project': _project,
          'collection': 'stok_masuk',
          'appid': '',
          'user_id': userId,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final data = json.decode(response.body);
          List<dynamic> items = [];

          if (data is List) {
            items = data;
          } else if (data is Map) {
            items = [data];
          }

          return items.map((item) {
            final Map<String, dynamic> stokData = Map<String, dynamic>.from(
              item,
            );

            return {
              'id': stokData['_id']?.toString() ?? '',
              'type': 'stok_masuk',
              'action': 'create',
              'title': 'Stok Masuk dari ${stokData['nama_vendor'] ?? 'Vendor'}',
              'description':
              'Qty: ${stokData['qty_pembelian'] ?? ''} - Harga: ${_formatCurrency(stokData['total_harga'] ?? '0')}',
              'user_name': stokData['user_name'] ?? 'User',
              'user_id': stokData['user_id'] ?? userId,
              'timestamp':
              stokData['tanggal_masuk'] ?? DateTime.now().toIso8601String(),
              'total':
              double.tryParse(stokData['total_harga']?.toString() ?? '0') ??
                  0,
              'color': '#667eea',
              'icon': 'download',
            };
          }).toList();
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // PERBAIKI: Method getAllUserActivities - HAPUS reference ke widget.userName
  Future<List<Map<String, dynamic>>> getAllUserActivities(String userId) async {
    try {
      if (kDebugMode) {
        print('🔄 Fetching ALL activities for user: $userId');
      }

      List<Map<String, dynamic>> allActivities = [];

      // Ambil data dari masing-masing collection secara spesifik
      final wasteFood = await getWasteFoodByUserId(userId);
      final stokKeluar = await getStokKeluarByUserId(userId);
      final stokMasuk = await getStokMasukByUserId(userId);

      allActivities.addAll(wasteFood);
      allActivities.addAll(stokKeluar);
      allActivities.addAll(stokMasuk);

      // Tambahkan data dummy jika tidak ada data sama sekali
      if (allActivities.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No data found, adding dummy data for testing');
        }

        // Data dummy untuk waste_food
        allActivities.add({
          'id': '1',
          'type': 'waste_food',
          'action': 'create',
          'title': 'Waste Food: Cabe Rawit',
          'description': 'Jenis: Busuk - Jumlah: 10 gr | Kerugian: Rp 25,000',
          'user_name': 'User', // Ganti dari widget.userName ke string
          'user_id': userId,
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'jumlah': 10,
          'kerugian': 25000,
          'color': '#f83600',
          'icon': 'delete',
        });

        // Data dummy untuk stok_keluar
        allActivities.add({
          'id': '2',
          'type': 'stok_keluar',
          'action': 'create',
          'title': 'Stok Keluar: INV10012026-01',
          'description': 'Invoice: INV10012026-01 - Total: Rp 150,000',
          'user_name': 'Kasir',
          'user_id': userId,
          'timestamp': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
          'total': 150000,
          'color': '#f093fb',
          'icon': 'upload',
        });
      }

      // Urutkan berdasarkan timestamp (terbaru dulu)
      allActivities.sort((a, b) {
        final timeA = a['timestamp'] ?? '';
        final timeB = b['timestamp'] ?? '';
        return timeB.compareTo(timeA);
      });

      if (kDebugMode) {
        print('🎯 Total activities found: ${allActivities.length}');
        print('📊 Breakdown:');
        print('  - Waste Food: ${wasteFood.length} items');
        print('  - Stok Keluar: ${stokKeluar.length} items');
        print('  - Stok Masuk: ${stokMasuk.length} items');
      }

      return allActivities;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in getAllUserActivities: $e');
      }
      return [];
    }
  }

  // Method untuk mengambil bahan baku, menu, staff, vendor (opsional)
  Future<List<Map<String, dynamic>>> getBahanBakuByUserId(String userId) async {
    try {
      final response = await http.post(
        Uri.parse(_getUrl('select/')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'token': _token,
          'project': _project,
          'collection': 'bahan_baku',
          'appid': '',
          'user_id': userId,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final data = json.decode(response.body);
          List<dynamic> items = [];

          if (data is List) {
            items = data;
          } else if (data is Map) {
            items = [data];
          }

          return items.map((item) {
            final Map<String, dynamic> bahanData = Map<String, dynamic>.from(
              item,
            );

            return {
              'id': bahanData['_id']?.toString() ?? '',
              'type': 'bahan_baku',
              'action': 'create',
              'title': 'Bahan Baku: ${bahanData['nama_bahan'] ?? 'Bahan'}',
              'description':
              'Stok: ${bahanData['stok_tersedia'] ?? ''} - Harga: ${_formatCurrency(bahanData['harga_per_unit'] ?? '0')}',
              'user_name': 'User',
              'user_id': userId,
              'timestamp':
              bahanData['created_at'] ?? DateTime.now().toIso8601String(),
              'total':
              double.tryParse(
                bahanData['harga_per_unit']?.toString() ?? '0',
              ) ??
                  0,
              'color': '#4facfe',
              'icon': 'shopping_basket',
            };
          }).toList();
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Method untuk menguji koneksi API
  Future<bool> testConnection() async {
    try {
      final response = await http.post(
        Uri.parse(_getUrl('select/')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'token': _token,
          'project': _project,
          'collection': 'waste_food',
          'limit': '1',
        },
      );

      if (kDebugMode) {
        print('🔗 Connection test: ${response.statusCode}');
        print('Response: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('❌ Connection test failed: $e');
      return false;
    }
  }

  // Simpan riwayat khusus menu
  static Future<void> saveMenuActivity({
    required String userId,
    required String menuId,
    required String menuName,
    required String type, // 'menu_update', 'menu_delete', 'menu_create'
    required String action,
    String userName = 'User',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'menu_history_$menuId';

      // Ambil data yang sudah ada
      final existingJson = prefs.getString(key) ?? '[]';
      final List<dynamic> existing = json.decode(existingJson);

      // Buat activity data
      final newActivity = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'menu_id': menuId,
        'menu_name': menuName,
        'type': type,
        'action': action,
        'title': _getMenuActivityTitle(type, menuName),
        'description': _getMenuActivityDescription(type, menuName, metadata),
        'user_name': userName,
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
        'color': _getMenuActivityColor(type),
        'icon': _getMenuActivityIcon(type),
      };

      // Tambah ke array (maksimal 50 item per menu)
      existing.add(newActivity);
      final toSave = existing.length > 50
          ? existing.sublist(existing.length - 50)
          : existing;

      await prefs.setString(key, json.encode(toSave));

      // Juga simpan ke riwayat umum
      await saveActivity(
        userId: userId,
        type: 'menu',
        title: _getMenuActivityTitle(type, menuName),
        description: _getMenuActivityDescription(type, menuName, metadata),
        userName: userName,
      );

      if (kDebugMode) {
        print('✅ Menu activity saved: $type - $menuName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving menu activity: $e');
      }
    }
  }

  // Ambil riwayat spesifik menu
  static Future<List<Map<String, dynamic>>> getMenuHistory(
      String menuId,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'menu_history_$menuId';
      final jsonString = prefs.getString(key) ?? '[]';

      final List<dynamic> data = json.decode(jsonString);

      // Konversi ke List<Map>
      final activities = data.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();

      // Urutkan terbaru dulu
      activities.sort((a, b) {
        final timeA = a['timestamp'] ?? '';
        final timeB = b['timestamp'] ?? '';
        return timeB.compareTo(timeA);
      });

      return activities;
    } catch (e) {
      return [];
    }
  }

  // Helper methods untuk menu activity
  static String _getMenuActivityTitle(String type, String menuName) {
    switch (type) {
      case 'menu_update':
        return 'Menu Diperbarui';
      case 'menu_delete':
        return 'Menu Dihapus';
      case 'menu_create':
        return 'Menu Ditambahkan';
      case 'stok_keluar':
        return 'Stok Keluar dari Menu';
      case 'stok_masuk':
        return 'Stok Masuk ke Menu';
      default:
        return 'Aktivitas Menu';
    }
  }

  static String _getMenuActivityDescription(
      String type,
      String menuName,
      Map<String, dynamic>? metadata,
      ) {
    switch (type) {
      case 'menu_update':
        return 'Menu "$menuName" telah diperbarui';
      case 'menu_delete':
        return 'Menu "$menuName" telah dihapus';
      case 'menu_create':
        return 'Menu "$menuName" telah ditambahkan';
      case 'stok_keluar':
        final qty = metadata?['quantity'] ?? '0';
        return 'Stok keluar dari menu "$menuName" sebanyak $qty';
      case 'stok_masuk':
        final qty = metadata?['quantity'] ?? '0';
        return 'Stok masuk ke menu "$menuName" sebanyak $qty';
      default:
        return 'Aktivitas pada menu "$menuName"';
    }
  }

  static String _getMenuActivityColor(String type) {
    switch (type) {
      case 'menu_update':
        return '#4facfe';
      case 'menu_delete':
        return '#f83600';
      case 'menu_create':
        return '#43e97b';
      case 'stok_keluar':
        return '#f093fb';
      case 'stok_masuk':
        return '#667eea';
      default:
        return '#667eea';
    }
  }

  static String _getMenuActivityIcon(String type) {
    switch (type) {
      case 'menu_update':
        return 'edit';
      case 'menu_delete':
        return 'delete';
      case 'menu_create':
        return 'add_circle';
      case 'stok_keluar':
        return 'upload';
      case 'stok_masuk':
        return 'download';
      default:
        return 'restaurant_menu';
    }
  }

  // Tambahkan method saveActivity di dalam class SimpleRiwayatService
  static Future<void> saveActivity({
    required String userId,
    required String type,
    required String title,
    required String description,
    required String userName,
    String? icon,
    String? color,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'general_activities_$userId';

      // Ambil data yang sudah ada
      final existingJson = prefs.getString(key) ?? '[]';
      final List<dynamic> existing = json.decode(existingJson);

      // Buat activity baru
      final newActivity = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'title': title,
        'description': description,
        'user_name': userName,
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'icon': icon ?? 'history',
        'color': color ?? '#667eea',
        'metadata': metadata ?? {},
      };

      // Tambah ke array (maksimal 100 item)
      existing.add(newActivity);
      final toSave = existing.length > 100
          ? existing.sublist(existing.length - 100)
          : existing;

      await prefs.setString(key, json.encode(toSave));

      if (kDebugMode) {
        print('✅ General activity saved: $type - $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving general activity: $e');
      }
    }
  }
}
