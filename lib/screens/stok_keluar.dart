import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../restapi.dart';
import '../config.dart';
import '../model/stok_keluar.dart';
import './stok_keluar_detail_page.dart';
import './kasir_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import constants
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class StokKeluarPage extends StatefulWidget {
  const StokKeluarPage({super.key});

  @override
  State<StokKeluarPage> createState() => _StokKeluarPageState();
}

class _StokKeluarPageState extends State<StokKeluarPage> {
  final DataService _dataService = DataService();
  List<StokKeluarModel> _stokKeluarList = [];
  List<StokKeluarModel> _filteredList = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStokKeluar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStokKeluar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== LOADING DATA STOK KELUAR ===');

      String? response;
      String foundCollection = 'stok_keluar';

      try {
        response = await _dataService.selectAll(
          token,
          project,
          'stok_keluar',
          appid,
        );

        if (response == null ||
            response.isEmpty ||
            response == '[]' ||
            response == 'null') {
          print(
            '⚠️ Data kosong di koleksi "stok_keluar", mencoba koleksi lain...',
          );

          final alternativeCollections = [
            'transactions',
            'orders',
            'penjualan',
            'sales',
          ];

          for (var collection in alternativeCollections) {
            try {
              final altResponse = await _dataService.selectAll(
                token,
                project,
                collection,
                appid,
              );

              if (altResponse != null &&
                  altResponse.isNotEmpty &&
                  altResponse != '[]' &&
                  altResponse != 'null') {
                response = altResponse;
                foundCollection = collection;
                print('✅ Data ditemukan di koleksi: $collection');
                break;
              }
            } catch (e) {
              print('❌ Gagal mengakses koleksi $collection: $e');
            }
          }
        }
      } catch (e) {
        print('❌ Error utama: $e');
        response = null;
      }

      if (response == null ||
          response.isEmpty ||
          response == '[]' ||
          response == 'null') {
        print('📭 Tidak ada data transaksi ditemukan di database');
        _checkKasirTransactions();
        return;
      }

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

      final newList = <StokKeluarModel>[];

      for (var item in dataList) {
        try {
          Map<String, dynamic> itemMap = {};

          if (item is Map) {
            item.forEach((key, value) {
              itemMap[key.toString()] = value;
            });
          }

          String invoice = '';
          String namaPemesanan = '';
          String noMeja = '';
          String tanggal = '';
          String menu = '';
          String? catatan;
          String? totalHarga;

          invoice =
              (itemMap['invoice'] as String?) ??
                  (itemMap['invoice_number'] as String?) ??
                  (itemMap['no_transaksi'] as String?) ??
                  (itemMap['kode_transaksi'] as String?) ??
                  'INV-${DateTime.now().millisecondsSinceEpoch}';

          namaPemesanan =
              (itemMap['nama_pemesanan'] as String?) ??
                  (itemMap['nama_pembeli'] as String?) ??
                  (itemMap['customer_name'] as String?) ??
                  (itemMap['pelanggan'] as String?) ??
                  'Tanpa Nama';

          noMeja =
              (itemMap['no_meja']?.toString()) ??
                  (itemMap['table_number']?.toString()) ??
                  (itemMap['meja']?.toString()) ??
                  '0';

          tanggal =
              (itemMap['tanggal'] as String?) ??
                  (itemMap['transaction_date'] as String?) ??
                  (itemMap['date'] as String?) ??
                  (itemMap['created_at'] as String?) ??
                  DateTime.now().toString();

          menu =
              (itemMap['menu'] as String?) ??
                  (itemMap['items'] as String?) ??
                  (itemMap['order_items'] as String?) ??
                  (itemMap['detail_pesanan'] as String?) ??
                  'Tidak ada menu';

          catatan = (itemMap['catatan'] as String?) ?? (itemMap['notes'] as String?);

          totalHarga = (itemMap['total_harga'] as String?) ??
                       (itemMap['totalHarga'] as String?) ??
                       (itemMap['total'] as String?) ??
                       (itemMap['amount'] as String?);

          String id =
              (itemMap['_id']?.toString()) ??
                  (itemMap['id']?.toString()) ??
                  '${invoice}_${DateTime.now().millisecondsSinceEpoch}';

          final stokKeluar = StokKeluarModel(
            id: id,
            invoice: invoice,
            nama_pemesanan: namaPemesanan,
            no_meja: noMeja,
            tanggal: tanggal,
            menu: menu,
            catatan: catatan,
            total_harga: totalHarga,
          );

          newList.add(stokKeluar);
        } catch (e) {
          print('⚠️ Error parsing item: $e');
        }
      }

      newList.sort((a, b) {
        try {
          return b.tanggal.compareTo(a.tanggal);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        _stokKeluarList = newList;
        _filteredList = List.from(_stokKeluarList);
        _isLoading = false;
      });

      print(
        '✅ Data stok keluar berhasil dimuat: ${_stokKeluarList.length} items',
      );
    } catch (e, stackTrace) {
      print('❌ ERROR LOADING STOK KELUAR: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Gagal memuat data stok keluar",
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _checkKasirTransactions() async {
    print('🔍 Checking for Kasir transactions...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTransactions = prefs.getStringList('kasir_transactions');

      if (savedTransactions != null && savedTransactions.isNotEmpty) {
        print(
          '📱 Found ${savedTransactions.length} transactions in local storage',
        );

        final List<StokKeluarModel> localList = [];

        for (var transactionJson in savedTransactions) {
          try {
            final Map<String, dynamic> transaction = json.decode(
              transactionJson,
            );

            final stokKeluar = StokKeluarModel(
              id:
              transaction['id'] ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              invoice: transaction['invoice'] ?? 'INV-LOCAL',
              nama_pemesanan: transaction['nama_pemesanan'] ?? 'Local Customer',
              no_meja: transaction['no_meja'] ?? '0',
              tanggal: transaction['tanggal'] ?? DateTime.now().toString(),
              menu: transaction['menu'] ?? 'Local Menu',
              catatan: transaction['catatan'],
              total_harga: transaction['total_harga'],
            );

            localList.add(stokKeluar);
          } catch (e) {
            print('⚠️ Error parsing local transaction: $e');
          }
        }

        setState(() {
          _stokKeluarList = localList;
          _filteredList = List.from(_stokKeluarList);
          _isLoading = false;
        });

        return;
      }
    } catch (e) {
      print('⚠️ Error checking local storage: $e');
    }

    setState(() {
      _stokKeluarList = [];
      _filteredList = [];
      _isLoading = false;
    });
  }

  void _filterStokKeluar(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _stokKeluarList;
      } else {
        _filteredList = _stokKeluarList
            .where(
              (stok) =>
          stok.invoice.toLowerCase().contains(query.toLowerCase()) ||
              stok.nama_pemesanan.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              stok.no_meja.toLowerCase().contains(query.toLowerCase()) ||
              stok.menu.toLowerCase().contains(query.toLowerCase()),
        )
            .toList();
      }
    });
  }

  void _showStokKeluarDetail(StokKeluarModel stok) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StokKeluarDetailPage(stokKeluar: stok),
      ),
    );
  }

  String _formatTime(String dateTimeStr) {
    try {
      final parts = dateTimeStr.split(' ');
      if (parts.length > 1) {
        final timePart = parts[1];
        final timeParts = timePart.split(':');
        if (timeParts.length >= 2) {
          return '${timeParts[0]}:${timeParts[1]}';
        }
      }
      return dateTimeStr;
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _formatDate(String dateTimeStr) {
    try {
      final parts = dateTimeStr.split(' ');
      if (parts.isNotEmpty) {
        final dateParts = parts[0].split('-');
        if (dateParts.length >= 3) {
          return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
        }
        return parts[0];
      }
      return dateTimeStr;
    } catch (e) {
      return dateTimeStr;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada transaksi',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Mulai buat transaksi baru di kasir untuk melihat riwayat stok keluar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KasirPage()),
              ).then((_) {
                _loadStokKeluar();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.point_of_sale, size: 20),
            label: Text('Buka Kasir', style: AppTextStyles.buttonMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(StokKeluarModel stok, int index) {
    final isEven = index % 2 == 0;

    // Helper function untuk mendapatkan judul menu yang singkat
    String getMenuTitle(String menuText) {
      if (menuText.isEmpty || menuText == 'Tidak ada menu') {
        return 'Tidak ada menu';
      }

      try {
        // Coba parse sebagai JSON
        if (menuText.trim().startsWith('[') ||
            menuText.trim().startsWith('{')) {
          try {
            final decoded = json.decode(menuText);
            if (decoded is List && decoded.isNotEmpty) {
              // Ambil dari array JSON
              final firstItem = decoded[0];
              if (firstItem is Map) {
                return firstItem['nama']?.toString() ??
                    firstItem['name']?.toString() ??
                    firstItem['item']?.toString() ??
                    'Menu';
              } else if (firstItem is String) {
                return firstItem;
              }
            } else if (decoded is Map) {
              // Ambil dari object JSON
              return decoded['nama']?.toString() ??
                  decoded['name']?.toString() ??
                  decoded['jenis']?.toString() ??
                  'Menu';
            }
          } catch (e) {
            // Jika gagal parse JSON, lanjut ke metode lain
          }
        }

        // Cek format <br> (HTML line break)
        if (menuText.contains('<br>')) {
          final parts = menuText.split('<br>');
          if (parts.isNotEmpty) {
            String firstItem = parts[0].trim();
            // Bersihkan dari tag HTML jika ada
            firstItem = firstItem.replaceAll(RegExp(r'<[^>]*>'), '');
            // Batasi panjang
            if (firstItem.length > 25) {
              return '${firstItem.substring(0, 25)}...';
            }
            return firstItem;
          }
        }

        // Cek format dengan koma atau separator lain
        final separators = [',', ';', '|', '/', '•'];
        for (var separator in separators) {
          if (menuText.contains(separator)) {
            final parts = menuText.split(separator);
            if (parts.isNotEmpty) {
              String firstItem = parts[0].trim();
              if (firstItem.length > 25) {
                return '${firstItem.substring(0, 25)}...';
              }
              return firstItem;
            }
          }
        }

        // Jika tidak ada separator, ambil 25 karakter pertama
        if (menuText.length > 25) {
          return '${menuText.substring(0, 25)}...';
        }

        return menuText;
      } catch (e) {
        // Fallback: tampilkan teks pendek
        if (menuText.length > 25) {
          return '${menuText.substring(0, 25)}...';
        }
        return menuText;
      }
    }

    // Helper function untuk mendapatkan jumlah item
    String getMenuItemCount(String menuText) {
      if (menuText.isEmpty || menuText == 'Tidak ada menu') {
        return '';
      }

      try {
        int count = 0;

        // Cek JSON array
        if (menuText.trim().startsWith('[')) {
          try {
            final decoded = json.decode(menuText) as List;
            count = decoded.length;
          } catch (e) {
            // Gagal parse JSON
          }
        }

        // Cek format <br>
        if (count == 0 && menuText.contains('<br>')) {
          count = menuText.split('<br>').length;
        }

        // Cek dengan separator lain
        if (count == 0) {
          final separators = [',', ';', '|', '/', '•'];
          for (var separator in separators) {
            if (menuText.contains(separator)) {
              count = menuText.split(separator).length;
              break;
            }
          }
        }

        // Jika masih 0, anggap 1 item
        if (count == 0) count = 1;

        return count > 1 ? '$count items' : '1 item';
      } catch (e) {
        return '';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showStokKeluarDetail(stok),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: isEven
                        ? AppColors.primaryGradient
                        : AppColors.secondaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Transaction Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              stok.invoice,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.priceTagGradientSimple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Meja ${stok.no_meja}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stok.nama_pemesanan,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(stok.tanggal),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      //bagian ini
                      // Menu Card - Hanya judul saja
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getMenuTitle(stok.menu),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    getMenuItemCount(stok.menu),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textDisabled,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Text(
                          //   _formatDate(stok.tanggal),
                          //   style: AppTextStyles.labelSmall.copyWith(
                          //     color: AppColors.textDisabled,
                          //   ),
                          // ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.remove_red_eye_outlined,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Detail',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar dengan Gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: AppColors.appBarGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     IconButton(
                  //       onPressed: () => Navigator.pop(context),
                  //       icon: const Icon(Icons.arrow_back, color: Colors.white),
                  //     ),
                  //     Text(
                  //       'Stok Keluar',
                  //       style: AppTextStyles.headlineLarge.copyWith(
                  //         color: Colors.white,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //     Container(
                  //       width: 40,
                  //       alignment: Alignment.center,
                  //       child: IconButton(
                  //         onPressed: () {},
                  //         icon: const Icon(
                  //           Icons.filter_list,
                  //           color: Colors.white,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterStokKeluar,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari invoice, nama pemesan',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Transaksi',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_filteredList.length}',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Transaksi ditemukan',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Memuat data...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
                  : _filteredList.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _loadStokKeluar,
                backgroundColor: AppColors.background,
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _filteredList.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionCard(
                      _filteredList[index],
                      index,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const KasirPage()),
          ).then((_) {
            _loadStokKeluar();
          });
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        icon: const Icon(Icons.point_of_sale),
        label: Text(
          'Kasir Baru',
          style: AppTextStyles.buttonMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
