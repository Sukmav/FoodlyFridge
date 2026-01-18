import 'package:flutter/material.dart';
import '../model/stok_keluar.dart';
import '../model/menu_model.dart';
import '../restapi.dart';
import '../config.dart';
import 'dart:convert';
import '../theme/app_colors.dart'; // IMPORT APP COLORS
import '../theme/text_styles.dart'; // IMPORT TEXT STYLES

class StokKeluarDetailPage extends StatefulWidget {
  final StokKeluarModel stokKeluar;

  const StokKeluarDetailPage({super.key, required this.stokKeluar});

  @override
  State<StokKeluarDetailPage> createState() => _StokKeluarDetailPageState();
}

class _StokKeluarDetailPageState extends State<StokKeluarDetailPage> {
  late List<MenuDetail> _menuDetails = [];
  bool _isLoading = false;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _parseMenuDetails();
  }

  void _parseMenuDetails() {
    setState(() {
      _isLoading = true;
    });

    try {
      final menuString = widget.stokKeluar.menu;
      List<MenuDetail> details = [];

      if (menuString.contains('<br>')) {
        final lines = menuString.split('<br>');
        for (var line in lines) {
          final item = _parseMenuItem(line);
          if (item != null) {
            details.add(item);
          }
        }
      } else {
        final item = _parseMenuItem(menuString);
        if (item != null) {
          details.add(item);
        }
      }

      setState(() {
        _menuDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      print('Error parsing menu: $e');
      setState(() {
        _menuDetails = [];
        _isLoading = false;
      });
    }
  }

  MenuDetail? _parseMenuItem(String menuItem) {
    try {
      // Coba format: "Menu: Sup Kentang telur"
      if (menuItem.contains('Menu')) {
        final parts = menuItem.split(':');
        if (parts.length >= 2) {
          final menuName = parts[1].trim();
          return MenuDetail(
            menuName: menuName,
            quantity: 1, // Default quantity
            bahanBakuList: [],
          );
        }
      }

      // Coba format: "Sup Kentang telur x 2"
      final quantityPattern = RegExp(
        r'(.+?)\s*x\s*(\d+)',
        caseSensitive: false,
      );
      final match = quantityPattern.firstMatch(menuItem);

      if (match != null) {
        final menuName = match.group(1)!.trim();
        final quantity = int.tryParse(match.group(2)!) ?? 1;
        return MenuDetail(
          menuName: menuName,
          quantity: quantity,
          bahanBakuList: [],
        );
      }

      // Jika tidak ada format yang cocok, gunakan seluruh string sebagai nama menu
      return MenuDetail(
        menuName: menuItem.trim(),
        quantity: 1,
        bahanBakuList: [],
      );
    } catch (e) {
      print('Error parsing menu item: $e');
      return null;
    }
  }

  Future<List<BahanBakuItem>> _getBahanBakuForMenu(String menuName) async {
    try {
      print('Fetching bahan baku for: $menuName'); // DEBUG

      // Clean menu name - hapus "Menu:" jika ada
      String cleanedMenuName = menuName;
      if (cleanedMenuName.startsWith('Menu:')) {
        cleanedMenuName = cleanedMenuName.substring(5).trim();
      }

      final response = await _dataService.selectAll(
        token,
        project,
        'menu',
        appid,
      );

      print('API Response: $response'); // DEBUG

      if (response.isNotEmpty && response != '[]' && response != 'null') {
        final decoded = json.decode(response);
        List<dynamic> menuDataList = [];

        if (decoded is Map && decoded.containsKey('data')) {
          menuDataList = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          menuDataList = decoded;
        }

        print('Found ${menuDataList.length} menu items'); // DEBUG

        for (var item in menuDataList) {
          final namaMenu = item['nama_menu']?.toString().toLowerCase() ?? '';
          final cleanedMenuLower = cleanedMenuName.toLowerCase();

          print('Comparing: "$cleanedMenuLower" with "$namaMenu"'); // DEBUG

          // Cek kesamaan (case insensitive dan partial match)
          if (namaMenu.contains(cleanedMenuLower) ||
              cleanedMenuLower.contains(namaMenu)) {
            print('Match found!'); // DEBUG
            List<BahanBakuItem> bahanBakuList = [];

            // Cek berbagai format bahan baku
            if (item['bahan_baku'] != null && item['bahan_baku'] is List) {
              final bahanList = item['bahan_baku'] as List;
              for (var bahan in bahanList) {
                bahanBakuList.add(
                  BahanBakuItem(
                    id_bahan: bahan['id_bahan']?.toString() ?? '',
                    nama_bahan: bahan['nama_bahan']?.toString() ?? '',
                    jumlah: bahan['jumlah']?.toString() ?? '0',
                    unit: bahan['unit']?.toString() ?? '',
                  ),
                );
              }
            } else if (item['bahan'] != null) {
              final bahanStr = item['bahan']?.toString() ?? '';
              final jumlahStr = item['jumlah']?.toString() ?? '';
              final satuanStr = item['satuan']?.toString() ?? '';

              print('Processing bahan string: $bahanStr'); // DEBUG

              if (bahanStr.isNotEmpty) {
                final bahanList = bahanStr.split(',');
                final jumlahList = jumlahStr.split(',');
                final satuanList = satuanStr.split(',');

                for (int i = 0; i < bahanList.length; i++) {
                  if (bahanList[i].trim().isNotEmpty) {
                    bahanBakuList.add(
                      BahanBakuItem(
                        id_bahan: '',
                        nama_bahan: bahanList[i].trim(),
                        jumlah: i < jumlahList.length
                            ? jumlahList[i].trim()
                            : '0',
                        unit: i < satuanList.length
                            ? satuanList[i].trim()
                            : 'pcs',
                      ),
                    );
                  }
                }
              }
            }

            print('Found ${bahanBakuList.length} bahan baku items'); // DEBUG
            return bahanBakuList;
          }
        }

        print('No matching menu found'); // DEBUG
      }
    } catch (e) {
      print('Error getting bahan baku: $e');
    }

    return [];
  }

  Widget _buildInvoiceHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient, // MENGGUNAKAN APPCOLORS
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3), // MENGGUNAKAN APPCOLORS
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.stokKeluar.invoice,
                style: AppTextStyles.headlineLarge.copyWith(
                  // MENGGUNAKAN TEXT STYLES
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  'Meja ${widget.stokKeluar.no_meja}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tanggal: ${widget.stokKeluar.tanggal}',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface, // MENGGUNAKAN APPCOLORS
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.5), // MENGGUNAKAN APPCOLORS
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Pemesan',
            style: AppTextStyles.headlineMedium.copyWith(
              // MENGGUNAKAN TEXT STYLES
              color: AppColors.textPrimary, // MENGGUNAKAN APPCOLORS
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 20,
                color: AppColors.textSecondary,
              ), // MENGGUNAKAN APPCOLORS
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Pembeli',
                      style: AppTextStyles.labelSmall.copyWith(
                        // MENGGUNAKAN TEXT STYLES
                        color: AppColors.textSecondary, // MENGGUNAKAN APPCOLORS
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.stokKeluar.nama_pemesanan,
                      style: AppTextStyles.bodyMedium.copyWith(
                        // MENGGUNAKAN TEXT STYLES
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary, // MENGGUNAKAN APPCOLORS
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.table_restaurant,
                size: 20,
                color: AppColors.textSecondary,
              ), // MENGGUNAKAN APPCOLORS
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nomor Meja',
                      style: AppTextStyles.labelSmall.copyWith(
                        // MENGGUNAKAN TEXT STYLES
                        color: AppColors.textSecondary, // MENGGUNAKAN APPCOLORS
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.stokKeluar.no_meja,
                      style: AppTextStyles.bodyMedium.copyWith(
                        // MENGGUNAKAN TEXT STYLES
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary, // MENGGUNAKAN APPCOLORS
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Pesanan',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Memuat detail menu...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else if (_menuDetails.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 60,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada detail menu',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  // Tampilkan data mentah untuk debugging
                  if (widget.stokKeluar.menu.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data mentah:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.stokKeluar.menu,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else
            Column(
              children: _menuDetails.map((menuDetail) {
                return FutureBuilder<List<BahanBakuItem>>(
                  future: _getBahanBakuForMenu(menuDetail.menuName),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildMenuItemCard(
                        menuDetail,
                        [], // Empty list while loading
                      );
                    }

                    if (snapshot.hasError) {
                      print('Error loading bahan baku: ${snapshot.error}');
                    }

                    final bahanBakuList = snapshot.data ?? [];
                    return _buildMenuItemCard(menuDetail, bahanBakuList);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(
      MenuDetail menuDetail,
      List<BahanBakuItem> bahanBakuList,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface, // MENGGUNAKAN APPCOLORS
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  menuDetail.menuName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    // MENGGUNAKAN TEXT STYLES
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, // MENGGUNAKAN APPCOLORS
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.stockOut.withOpacity(
                      0.1,
                    ), // MENGGUNAKAN APPCOLORS
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.stockOut.withOpacity(
                        0.3,
                      ), // MENGGUNAKAN APPCOLORS
                    ),
                  ),
                  child: Text(
                    '${menuDetail.quantity} porsi',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.stockOut, // MENGGUNAKAN APPCOLORS
                    ),
                  ),
                ),
              ],
            ),

            if (bahanBakuList.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Bahan Baku yang Digunakan:',
                style: AppTextStyles.bodyMedium.copyWith(
                  // MENGGUNAKAN TEXT STYLES
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary, // MENGGUNAKAN APPCOLORS
                ),
              ),
              const SizedBox(height: 12),

              // Table header
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card, // MENGGUNAKAN APPCOLORS
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Bahan',
                          style: AppTextStyles.labelMedium.copyWith(
                            // MENGGUNAKAN TEXT STYLES
                            fontWeight: FontWeight.w700,
                            color:
                            AppColors.textPrimary, // MENGGUNAKAN APPCOLORS
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '/porsi',
                          style: AppTextStyles.labelMedium.copyWith(
                            // MENGGUNAKAN TEXT STYLES
                            fontWeight: FontWeight.w700,
                            color:
                            AppColors.textPrimary, // MENGGUNAKAN APPCOLORS
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          style: AppTextStyles.labelMedium.copyWith(
                            // MENGGUNAKAN TEXT STYLES
                            fontWeight: FontWeight.w700,
                            color:
                            AppColors.textPrimary, // MENGGUNAKAN APPCOLORS
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bahan baku items
              ...bahanBakuList.map((bahan) {
                final jumlahPerPorsi = double.tryParse(bahan.jumlah) ?? 0.0;
                final totalJumlah = jumlahPerPorsi * menuDetail.quantity;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          bahan.nama_bahan,
                          style: AppTextStyles.bodyMedium.copyWith(
                            // MENGGUNAKAN TEXT STYLES
                            fontWeight: FontWeight.w500,
                            color:
                            AppColors.textPrimary, // MENGGUNAKAN APPCOLORS
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '$jumlahPerPorsi ${bahan.unit}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            // MENGGUNAKAN TEXT STYLES
                            color: AppColors
                                .textSecondary, // MENGGUNAKAN APPCOLORS
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '$totalJumlah ${bahan.unit}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            // MENGGUNAKAN TEXT STYLES
                            fontWeight: FontWeight.w600,
                            color: AppColors.success, // MENGGUNAKAN APPCOLORS
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Tidak ada data bahan baku tersedia',
                  style: AppTextStyles.bodyMedium.copyWith(
                    // MENGGUNAKAN TEXT STYLES
                    color: AppColors.textSecondary, // MENGGUNAKAN APPCOLORS
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // MENGGUNAKAN APPCOLORS
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary, // MENGGUNAKAN APPCOLORS
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Stok Keluar',
          style: AppTextStyles.titleLarge.copyWith(
            // MENGGUNAKAN TEXT STYLES
            color: AppColors.textPrimary, // MENGGUNAKAN APPCOLORS
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInvoiceHeader(),
            _buildCustomerInfo(),
            _buildMenuSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Model untuk detail menu
class MenuDetail {
  final String menuName;
  final int quantity;
  final List<BahanBakuItem> bahanBakuList;

  MenuDetail({
    required this.menuName,
    required this.quantity,
    required this.bahanBakuList,
  });
}
