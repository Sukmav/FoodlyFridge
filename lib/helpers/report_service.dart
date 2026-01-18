// lib/helpers/report_service.dart - VERSI YANG BENAR
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:math' as Math;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config.dart';
import '../restapi.dart'; // IMPORT DataService seperti di StokKeluarPage
import '../model/daily_data_model.dart';

class ReportService {
  final DataService _dataService = DataService(); // Gunakan DataService
  
  // Method untuk mendapatkan statistik overview
  Future<Map<String, dynamic>> getOverviewStats(String userId) async {
    print('📊 ========== GET OVERVIEW STATS ==========');
    print('User ID: $userId');
    
    try {
      // AMBIL DATA SAMA PERSIS SEPERTI DI STOK KELUAR PAGE
      print('=== LOADING DATA SAMA SEPERTI DI STOK KELUAR PAGE ===');
      
      // 1. Ambil data stok_keluar - TANPA filter user_id
      String stokKeluarResponse = await _dataService.selectAll(
        token,
        project,
        'stok_keluar',
        appid,
      );
      
      print('Stok keluar response length: ${stokKeluarResponse.length}');
      
      // Parse data sama seperti di StokKeluarPage
      List<Map<String, dynamic>> stokKeluarList = _parseDataResponse(stokKeluarResponse);
      
      // 2. Ambil data waste_food
      String wasteFoodResponse = await _dataService.selectAll(
        token,
        project,
        'waste_food',
        appid,
      );
      List<Map<String, dynamic>> wasteFoodList = _parseDataResponse(wasteFoodResponse);
      
      // 3. Ambil data stok_masuk
      String stokMasukResponse = await _dataService.selectAll(
        token,
        project,
        'stok_masuk',
        appid,
      );
      List<Map<String, dynamic>> stokMasukList = _parseDataResponse(stokMasukResponse);
      
      print('📦 Data counts (menggunakan DataService.selectAll):');
      print('  - stok_keluar: ${stokKeluarList.length} items');
      print('  - waste_food: ${wasteFoodList.length} items');
      print('  - stok_masuk: ${stokMasukList.length} items');
      
      // DEBUG: Tampilkan data stok_keluar
      if (stokKeluarList.isNotEmpty) {
        print('📋 Data stok_keluar yang ditemukan:');
        for (var i = 0; i < (stokKeluarList.length > 3 ? 3 : stokKeluarList.length); i++) {
          var item = stokKeluarList[i];
          print('  ${i+1}. Invoice: ${item['invoice']}');
          print('     Total Harga: ${item['total_harga']}');
          print('     User ID di DB: ${item['user_id']}');
        }
      }
      
      // Hitung total penjualan
      double totalPenjualan = 0;
      for (var item in stokKeluarList) {
        final hargaStr = item['total_harga']?.toString() ?? '0';
        final harga = double.tryParse(hargaStr) ?? 0;
        totalPenjualan += harga;
        print('  🧮 Menghitung: $hargaStr -> $harga (Total: $totalPenjualan)');
      }
      
      // Hitung total transaksi
      int totalTransaksi = stokKeluarList.length;
      
      // Hitung total waste
      double totalWaste = 0;
      for (var item in wasteFoodList) {
        final kerugianStr = item['total_kerugian']?.toString() ?? '0';
        totalWaste += double.tryParse(kerugianStr) ?? 0;
      }
      
      // Hitung total stok masuk
      double totalStokMasuk = 0;
      for (var item in stokMasukList) {
        final hargaStr = item['total_harga']?.toString() ?? '0';
        totalStokMasuk += double.tryParse(hargaStr) ?? 0;
      }
      
      // Format currency
      final currencyFormat = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      
      final result = {
        'totalPenjualan': totalPenjualan,
        'totalPenjualanFormatted': currencyFormat.format(totalPenjualan),
        'totalTransaksi': totalTransaksi,
        'totalTransaksiFormatted': NumberFormat().format(totalTransaksi),
        'totalWaste': totalWaste,
        'totalWasteFormatted': currencyFormat.format(totalWaste),
        'totalStokMasuk': totalStokMasuk,
        'totalStokMasukFormatted': currencyFormat.format(totalStokMasuk),
        'profitBersih': totalPenjualan - totalStokMasuk - totalWaste,
        'profitBersihFormatted': currencyFormat.format(totalPenjualan - totalStokMasuk - totalWaste),
        'stokKeluarCount': stokKeluarList.length,
        'wasteFoodCount': wasteFoodList.length,
        'stokMasukCount': stokMasukList.length,
      };
      
      print('📊 HASIL OVERVIEW STATS:');
      print('  - Total Penjualan: ${result['totalPenjualanFormatted']}');
      print('  - Total Transaksi: ${result['totalTransaksi']} transaksi');
      print('  - Total Waste: ${result['totalWasteFormatted']}');
      print('  - Total Stok Masuk: ${result['totalStokMasukFormatted']}');
      print('========================================\n');
      
      return result;
    } catch (e) {
      print('❌ Error in getOverviewStats: $e');
      return _getDefaultStats();
    }
  }
  
  // Helper method untuk parse response sama seperti di StokKeluarPage
  List<Map<String, dynamic>> _parseDataResponse(String response) {
    List<Map<String, dynamic>> result = [];
    
    if (response.isEmpty || response == 'null' || response == '[]') {
      return result;
    }
    
    try {
      final dynamic decodedData = json.decode(response);
      List<dynamic> dataList = [];

      if (decodedData is Map) {
        if (decodedData.containsKey('data')) {
          dataList = decodedData['data'] as List<dynamic>;
        } else if (decodedData.containsKey('items')) {
          dataList = decodedData['items'] as List<dynamic>;
        } else if (decodedData.containsKey('transactions')) {
          dataList = decodedData['transactions'] as List<dynamic>;
        } else {
          // Coba semua keys
          final keys = decodedData.keys.toList();
          for (var key in keys) {
            if (decodedData[key] is List) {
              dataList = decodedData[key] as List<dynamic>;
              break;
            }
          }
        }
      } else if (decodedData is List) {
        dataList = decodedData;
      }

      for (var item in dataList) {
        try {
          Map<String, dynamic> itemMap = {};

          if (item is Map) {
            item.forEach((key, value) {
              itemMap[key.toString()] = value;
            });
          }

          // Konversi ke format standar seperti di StokKeluarPage
          result.add(itemMap);
        } catch (e) {
          print('⚠️ Error parsing item: $e');
        }
      }
    } catch (e) {
      print('❌ Error parsing response: $e');
    }
    
    return result;
  }
  
  // Method untuk mendapatkan aktivitas terkini
  Future<List<Map<String, dynamic>>> getRecentActivities(String userId) async {
    try {
      List<Map<String, dynamic>> allActivities = [];
      
      // Ambil data menggunakan DataService seperti di StokKeluarPage
      String stokKeluarResponse = await _dataService.selectAll(
        token,
        project,
        'stok_keluar',
        appid,
      );
      
      String wasteFoodResponse = await _dataService.selectAll(
        token,
        project,
        'waste_food',
        appid,
      );
      
      String stokMasukResponse = await _dataService.selectAll(
        token,
        project,
        'stok_masuk',
        appid,
      );
      
      List<Map<String, dynamic>> stokKeluarList = _parseDataResponse(stokKeluarResponse);
      List<Map<String, dynamic>> wasteFoodList = _parseDataResponse(wasteFoodResponse);
      List<Map<String, dynamic>> stokMasukList = _parseDataResponse(stokMasukResponse);
      
      // Format currency
      final currencyFormat = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      
      // Helper untuk parse tanggal
      String parseDate(dynamic dateString) {
        if (dateString == null) return DateTime.now().toIso8601String();
        
        try {
          // Format dd/MM/yyyy HH:mm
          if (dateString.toString().contains('/')) {
            final parts = dateString.toString().split(' ');
            if (parts.isNotEmpty) {
              final dateParts = parts[0].split('/');
              if (dateParts.length == 3) {
                final day = int.tryParse(dateParts[0]) ?? 1;
                final month = int.tryParse(dateParts[1]) ?? 1;
                final year = int.tryParse(dateParts[2]) ?? DateTime.now().year;
                return DateTime(year, month, day).toIso8601String();
              }
            }
          }
          return DateTime.parse(dateString.toString()).toIso8601String();
        } catch (e) {
          return DateTime.now().toIso8601String();
        }
      }
      
      // Konversi data stok_keluar
      for (var item in stokKeluarList.take(5)) {
        final invoice = item['invoice']?.toString() ?? 'Transaksi';
        final total = double.tryParse(item['total_harga']?.toString() ?? '0') ?? 0;
        final namaPemesan = item['nama_pemesanan']?.toString() ?? 'Pelanggan';
        final tanggal = parseDate(item['tanggal']);
        
        allActivities.add({
          'id': item['_id']?.toString() ?? '',
          'type': 'stok_keluar',
          'title': 'Penjualan: $invoice',
          'description': 'Pemesan: $namaPemesan - Total: ${currencyFormat.format(total)}',
          'user_name': item['nama_kasir'] ?? 'Kasir',
          'timestamp': tanggal,
          'color': '#f093fb',
          'icon': 'upload',
          'total': total,
        });
      }
      
      // Konversi data waste_food
      for (var item in wasteFoodList.take(5)) {
        final namaBahan = item['nama_bahan']?.toString() ?? 'Bahan';
        final jumlah = item['jumlah_terbuang']?.toString() ?? '0';
        final unit = item['unit']?.toString() ?? 'gr';
        final kerugian = double.tryParse(item['total_kerugian']?.toString() ?? '0') ?? 0;
        final tanggal = parseDate(item['tanggal']);
        
        allActivities.add({
          'id': item['_id']?.toString() ?? '',
          'type': 'waste_food',
          'title': 'Waste: $namaBahan',
          'description': 'Jumlah: $jumlah $unit - Kerugian: ${currencyFormat.format(kerugian)}',
          'user_name': item['user_name'] ?? 'User',
          'timestamp': tanggal,
          'color': '#f83600',
          'icon': 'delete',
          'total': kerugian,
        });
      }
      
      // Konversi data stok_masuk
      for (var item in stokMasukList.take(5)) {
        final vendor = item['nama_vendor']?.toString() ?? 'Vendor';
        final qty = item['qty_pembelian']?.toString() ?? '0';
        final total = double.tryParse(item['total_harga']?.toString() ?? '0') ?? 0;
        final tanggal = parseDate(item['tanggal_masuk']);
        
        allActivities.add({
          'id': item['_id']?.toString() ?? '',
          'type': 'stok_masuk',
          'title': 'Pembelian dari $vendor',
          'description': 'Qty: $qty - Total: ${currencyFormat.format(total)}',
          'user_name': item['user_name'] ?? 'User',
          'timestamp': tanggal,
          'color': '#667eea',
          'icon': 'download',
          'total': total,
        });
      }
      
      // Urutkan berdasarkan timestamp
      allActivities.sort((a, b) {
        final timeA = a['timestamp'] ?? '';
        final timeB = b['timestamp'] ?? '';
        return timeB.compareTo(timeA);
      });
      
      return allActivities.take(10).toList();
      
    } catch (e) {
      print('❌ Error in getRecentActivities: $e');
      return [];
    }
  }
  
  // Data default jika error
  Map<String, dynamic> _getDefaultStats() {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    
    return {
      'totalPenjualan': 0,
      'totalPenjualanFormatted': currencyFormat.format(0),
      'totalTransaksi': 0,
      'totalTransaksiFormatted': '0',
      'totalWaste': 0,
      'totalWasteFormatted': currencyFormat.format(0),
      'totalStokMasuk': 0,
      'totalStokMasukFormatted': currencyFormat.format(0),
      'profitBersih': 0,
      'profitBersihFormatted': currencyFormat.format(0),
      'stokKeluarCount': 0,
      'wasteFoodCount': 0,
      'stokMasukCount': 0,
    };
  }
  
  // Untuk analysis dan chart data, bisa ikuti pola yang sama
// Di ReportService.dart - Tambahkan method lengkap:

Future<Map<String, dynamic>> getAnalysisData(String userId) async {
  print('📊 ========== GET ANALYSIS DATA ==========');
  
  try {
    // Ambil data yang diperlukan
    final stokKeluarResponse = await _dataService.selectAll(
      token,
      project,
      'stok_keluar',
      appid,
    );
    
    final wasteFoodResponse = await _dataService.selectAll(
      token,
      project,
      'waste_food',
      appid,
    );
    
    final stokMasukResponse = await _dataService.selectAll(
      token,
      project,
      'stok_masuk',
      appid,
    );

    final menuMakananResponse = await _dataService.selectAll(
      token,
      project,
      'menu_makanan', // Nama tabel menu
      appid,
    );
    
    final List<Map<String, dynamic>> stokKeluarList = _parseDataResponse(stokKeluarResponse);
    final List<Map<String, dynamic>> wasteFoodList = _parseDataResponse(wasteFoodResponse);
    final List<Map<String, dynamic>> stokMasukList = _parseDataResponse(stokMasukResponse);
    final List<Map<String, dynamic>> menuMakananList = _parseDataResponse(menuMakananResponse);
    
    // DEBUG: Cek data menu_makanan
    print('📋 Data menu_makanan:');
    print('  - Total items: ${menuMakananList.length}');
    if (menuMakananList.isNotEmpty) {
      print('  - Sample item: ${menuMakananList.first}');
      print('  - Available fields: ${menuMakananList.first.keys.toList()}');
    }
    
    // Hitung totals
    double totalPenjualan = 0;
    int totalTransaksi = stokKeluarList.length;
    double totalWaste = 0;
    double totalStokMasuk = 0;
    
    for (var item in stokKeluarList) {
      totalPenjualan += double.tryParse(item['total_harga']?.toString() ?? '0') ?? 0;
    }
    
    for (var item in wasteFoodList) {
      totalWaste += double.tryParse(item['total_kerugian']?.toString() ?? '0') ?? 0;
    }
    
    for (var item in stokMasukList) {
      totalStokMasuk += double.tryParse(item['total_harga']?.toString() ?? '0') ?? 0;
    }
    
    // Hitung analisis
    double marginKeuntungan = 0;
    if (totalPenjualan > 0) {
      marginKeuntungan = ((totalPenjualan - totalStokMasuk - totalWaste) / totalPenjualan) * 100;
    }
    
    double wastePercentage = 0;
    if (totalPenjualan > 0) {
      wastePercentage = (totalWaste / totalPenjualan) * 100;
    }
    
    double avgTransaksi = 0;
    if (totalTransaksi > 0) {
      avgTransaksi = totalPenjualan / totalTransaksi;
    }
    
    // PERBAIKAN 1: Hitung menu unik dari menu_makanan
    int totalMenuCount = 0;
    try {
      // Coba hitung dari nama menu di tabel menu_makanan
      Set<String> uniqueMenuNames = {};
      for (var menu in menuMakananList) {
        final menuName = menu['nama_menu']?.toString() ?? 
                        menu['nama']?.toString() ??
                        menu['menu_name']?.toString() ??
                        menu['name']?.toString();
        
        if (menuName != null && menuName.isNotEmpty) {
          uniqueMenuNames.add(menuName);
        }
      }
      totalMenuCount = uniqueMenuNames.length;
      
      // Jika masih 0, coba hitung berdasarkan ID unik
      if (totalMenuCount == 0) {
        Set<String> uniqueMenuIds = {};
        for (var menu in menuMakananList) {
          final menuId = menu['_id']?.toString() ?? 
                        menu['id']?.toString() ??
                        menu['menu_id']?.toString();
          if (menuId != null && menuId.isNotEmpty) {
            uniqueMenuIds.add(menuId);
          }
        }
        totalMenuCount = uniqueMenuIds.length;
      }
      
      // Jika masih 0, gunakan jumlah total items
      if (totalMenuCount == 0 && menuMakananList.isNotEmpty) {
        totalMenuCount = menuMakananList.length;
      }
      
    } catch (e) {
      print('⚠️ Error calculating menu count: $e');
      totalMenuCount = menuMakananList.length;
    }
    
    // PERBAIKAN 2: Hitung juga menu yang terjual dari stok_keluar
    Set<String> soldMenuNames = {};
    try {
      for (var item in stokKeluarList) {
        // Coba berbagai field yang mungkin berisi nama menu
        final menuName = item['nama_menu']?.toString() ?? 
                        item['menu']?.toString() ??
                        item['item_name']?.toString() ??
                        item['product']?.toString();
        
        if (menuName != null && menuName.isNotEmpty) {
          soldMenuNames.add(menuName);
        }
        
        // Coba cari di detail items jika ada
        final items = item['items'] ?? item['details'] ?? item['products'];
        if (items is List) {
          for (var detail in items) {
            if (detail is Map) {
              final detailMenu = detail['nama_menu']?.toString() ?? 
                                detail['menu']?.toString();
              if (detailMenu != null && detailMenu.isNotEmpty) {
                soldMenuNames.add(detailMenu);
              }
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Error calculating sold menus: $e');
    }
    
    print('📊 Analysis Results:');
    print('  - Margin Keuntungan: ${marginKeuntungan.toStringAsFixed(1)}%');
    print('  - Waste Percentage: ${wastePercentage.toStringAsFixed(1)}%');
    print('  - Total Menu (from menu_makanan): $totalMenuCount');
    print('  - Unique Menus Sold: ${soldMenuNames.length}');
    print('  - Avg Transaksi: $avgTransaksi');
    print('  - Total Penjualan: $totalPenjualan');
    print('  - Total Transaksi: $totalTransaksi');
    
    // PERBAIKAN 3: Return dengan data yang benar
    return {
      'marginKeuntungan': marginKeuntungan,
      'wastePercentage': wastePercentage,
      'totalMenu': totalMenuCount, // <-- GUNAKAN totalMenuCount dari menu_makanan
      'uniqueMenusSold': soldMenuNames.length, // Bonus data
      'avgTransaksi': avgTransaksi,
      'totalPenjualan': totalPenjualan,
      'totalTransaksi': totalTransaksi,
      'totalWaste': totalWaste,
      'totalStokMasuk': totalStokMasuk,
    };
    
  } catch (e) {
    print('❌ Error in getAnalysisData: $e');
    return {
      'marginKeuntungan': 0.0,
      'wastePercentage': 0.0,
      'totalMenu': 0,
      'uniqueMenusSold': 0,
      'avgTransaksi': 0.0,
      'totalPenjualan': 0.0,
      'totalTransaksi': 0,
      'totalWaste': 0.0,
      'totalStokMasuk': 0.0,
    };
  }
}
  
  Future<Map<String, dynamic>> getChartData(String userId) async {
    try {
      // Implementasi similar...
      return {};
    } catch (e) {
      return {};
    }
  }
  
  Future<bool> exportReport(String userId, String format) async {
    await Future.delayed(Duration(seconds: 2));
    return true;
  }

  // Tambahkan method ini di ReportService
// Perbaiki method getDailyChartData
Future<Map<String, dynamic>> getDailyChartData(String userId) async {
  print('📊 ========== GET DAILY CHART DATA ==========');
  
  try {
    // Ambil data
    final stokKeluarResponse = await _dataService.selectAll(
      token,
      project,
      'stok_keluar',
      appid,
    );
    
    final wasteFoodResponse = await _dataService.selectAll(
      token,
      project,
      'waste_food',
      appid,
    );
    
    final List<Map<String, dynamic>> stokKeluarList = _parseDataResponse(stokKeluarResponse);
    final List<Map<String, dynamic>> wasteFoodList = _parseDataResponse(wasteFoodResponse);
    
    print('📦 Data loaded: ${stokKeluarList.length} stok_keluar, ${wasteFoodList.length} waste_food');
    
    // Siapkan data untuk 7 hari terakhir
    final now = DateTime.now();
    final List<DailyData> dailyDataList = [];
    
    // Buat 7 hari terakhir
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayLabel = _formatDayLabel(date);
      
      dailyDataList.add(DailyData(
        day: dayLabel,
        penjualan: 0.0,
        transaksi: 0.0,
        waste: 0.0,
        date: date,
      ));
    }
    
    // SIMPLE APPROACH: Group by hari berdasarkan string matching
    // Ini lebih toleran terhadap format tanggal yang berbeda
    
    Map<String, DailyData> dailyDataMap = {};
    for (var data in dailyDataList) {
      dailyDataMap[data.day] = data;
    }
    
    // Proses stok_keluar dengan SIMPLE matching
    for (var item in stokKeluarList) {
      try {
        final dateStr = item['tanggal']?.toString() ?? '';
        if (dateStr.isNotEmpty) {
          // Cari label hari berdasarkan string matching sederhana
          String? matchedDay = _findDayLabelByDateString(dateStr, dailyDataList);
          
          if (matchedDay != null && dailyDataMap.containsKey(matchedDay)) {
            final totalHarga = double.tryParse(item['total_harga']?.toString() ?? '0') ?? 0;
            final currentData = dailyDataMap[matchedDay]!;
            
            dailyDataMap[matchedDay] = DailyData(
              day: currentData.day,
              penjualan: currentData.penjualan + totalHarga,
              transaksi: currentData.transaksi + 1,
              waste: currentData.waste,
              date: currentData.date,
            );
          }
        }
      } catch (e) {
        print('⚠️ Error: $e');
      }
    }
    
    // Proses waste_food
    for (var item in wasteFoodList) {
      try {
        final dateStr = item['tanggal']?.toString() ?? '';
        if (dateStr.isNotEmpty) {
          String? matchedDay = _findDayLabelByDateString(dateStr, dailyDataList);
          
          if (matchedDay != null && dailyDataMap.containsKey(matchedDay)) {
            final totalKerugian = double.tryParse(item['total_kerugian']?.toString() ?? '0') ?? 0;
            final currentData = dailyDataMap[matchedDay]!;
            
            dailyDataMap[matchedDay] = DailyData(
              day: currentData.day,
              penjualan: currentData.penjualan,
              transaksi: currentData.transaksi,
              waste: currentData.waste + totalKerugian,
              date: currentData.date,
            );
          }
        }
      } catch (e) {
        print('⚠️ Error waste: $e');
      }
    }
    
    // Convert map back to list
    final resultList = dailyDataList.map((data) => dailyDataMap[data.day] ?? data).toList();
    
    // Print results
    print('📊 Daily Chart Data:');
    for (var data in resultList) {
      print('  - ${data.day}: Penjualan=${data.penjualan}, Transaksi=${data.transaksi}');
    }
    
    return {
      'dailyData': resultList,
      'dayLabels': resultList.map((d) => d.day).toList(),
    };
    
  } catch (e) {
    print('❌ Error: $e');
    return _getDefaultDailyChartData();
  }
}

// Helper untuk matching tanggal sederhana
String? _findDayLabelByDateString(String dateStr, List<DailyData> dailyDataList) {
  try {
    // Coba extract tanggal dari string
    String? extractedDate;
    
    // Cari pola dd/MM/yyyy
    RegExp regex = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})');
    Match? match = regex.firstMatch(dateStr);
    
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      
      final date = DateTime(year, month, day);
      return _formatDayLabel(date);
    }
    
    // Jika tidak match, coba format lain
    // Atau return null untuk di-skip
    return null;
    
  } catch (e) {
    return null;
  }
}

  // Helper untuk parse tanggal dengan berbagai format
DateTime? _parseTanggal(String dateString) {
  if (dateString == null || dateString.isEmpty) {
    return null;
  }

  try {
    print('🔍 Parsing date: $dateString');
    
    // Coba format ISO 8601 (dari API biasanya)
    if (dateString.contains('T')) {
      return DateTime.parse(dateString);
    }
    
    // Coba format dd/MM/yyyy HH:mm:ss (format Indonesia)
    if (dateString.contains('/')) {
      // Hilangkan detik jika ada
      String cleanDate = dateString;
      if (cleanDate.contains(':')) {
        final parts = cleanDate.split(':');
        if (parts.length > 2) {
          cleanDate = parts.sublist(0, 2).join(':');
        }
      }
      
      // Format: 18/01/2026 15:54
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      return dateFormat.parse(cleanDate);
    }
    
    // Coba format lainnya
    final formats = [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd',
      'dd-MM-yyyy HH:mm',
      'dd/MM/yyyy',
    ];
    
    for (var format in formats) {
      try {
        return DateFormat(format).parse(dateString);
      } catch (e) {
        continue;
      }
    }
    
    // Coba parsing langsung
    return DateTime.parse(dateString);
  } catch (e) {
    print('❌ Error parsing date "$dateString": $e');
    return null;
  }
}

  // Helper untuk format label hari
  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hari Ini';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Kemarin';
    } else {
      final daysOfWeek = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
      return daysOfWeek[date.weekday % 7];
    }
  }

  // Data default untuk chart harian
  Map<String, dynamic> _getDefaultDailyChartData() {
    final now = DateTime.now();
    final List<String> dayLabels = [];
    final List<DailyData> dailyDataList = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayLabel = _formatDayLabel(date);
      dayLabels.add(dayLabel);
      
      dailyDataList.add(DailyData(
        day: dayLabel,
        penjualan: 0.0,
        transaksi: 0.0,
        waste: 0.0,
        date: date,
      ));
    }
    
    return {
      'dailyData': dailyDataList,
      'dayLabels': dayLabels,
      'penjualanPerHari': {},
      'transaksiPerHari': {},
      'wastePerHari': {},
    };
  }
}