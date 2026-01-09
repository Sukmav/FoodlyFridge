import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config.dart';
import '../restapi.dart';
import '../model/menu_model.dart';
import '../model/stok_keluar.dart';
import 'struk_page.dart';
import '../model/bahan_baku_model.dart';
import '../theme/app_colors.dart'; // IMPORT APP COLORS
import '../theme/text_styles.dart'; // IMPORT TEXT STYLES
import 'package:shared_preferences/shared_preferences.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({Key? key}) : super(key: key);

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  final DataService _dataService = DataService();
  final TextEditingController _namaPemesanController = TextEditingController();
  final TextEditingController _noMejaController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  String _userId = ''; // Variabel untuk menyimpan userId
  String _staffName = '';


  List<MenuModel> _menuList = [];
  List<BahanBakuModel> _bahanBakuList = [];
  bool _isLoading = false;
  bool _isProcessing = false;

  // Data pesanan
  final List<CartItem> _cartItems = [];

  // Untuk operasi harga
  double _totalHarga = 0.0;
  String _searchQuery = '';

  // Kategori filter
  String _selectedCategory = 'Semua';
  List<String> _categories = ['Semua'];

  // Untuk invoice counter
  Map<String, int> _invoiceCounter = {};
  String _lastInvoiceDate = '';

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Panggil ini dulu
    _loadData();
    _initInvoiceCounter();
  }

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ?? 'default_owner_id';
      _staffName = prefs.getString('staff_nama') ?? 'Staff';
    });

    print('User ID loaded: $_userId');
    print('Staff Name: $_staffName');
  }

  void _initInvoiceCounter() {
    final now = DateTime.now();
    final today = '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';
    _lastInvoiceDate = today;
    _invoiceCounter[today] = 1; // Mulai dari 1
  }

  String _generateInvoice() {
    final now = DateTime.now();
    final today = '${now.day.toString().padLeft(2, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.year}';

    if (_lastInvoiceDate != today) {
      _invoiceCounter.clear();
      _lastInvoiceDate = today;
      _invoiceCounter[today] = 1;
    } else {
      _invoiceCounter[today] = (_invoiceCounter[today] ?? 0) + 1;
    }

    final counter = _invoiceCounter[today]!;
    return 'INV$today-${counter.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final menuResponse = await _dataService.selectAll(token, project, 'menu', appid);
      List<MenuModel> loadedMenus = [];
      List<String> loadedCategories = ['Semua'];

      if (menuResponse.isNotEmpty && menuResponse != '[]' && menuResponse != 'null') {
        try {
          final decoded = json.decode(menuResponse);
          List<dynamic> menuDataList = [];

          if (decoded is Map && decoded.containsKey('data')) {
            menuDataList = decoded['data'] as List<dynamic>;
          } else if (decoded is List) {
            menuDataList = decoded;
          }

          loadedMenus = menuDataList.map<MenuModel>((item) {
            try {
              Map<String, dynamic> transformedItem = Map<String, dynamic>.from(item);

              if (item.containsKey('id') && !item.containsKey('_id')) {
                transformedItem['_id'] = item['id'];
              }

              if (item.containsKey('bahan') && !item.containsKey('bahan_baku')) {
                final bahanStr = item['bahan']?.toString() ?? '';
                final jumlahStr = item['jumlah']?.toString() ?? '';
                final satuanStr = item['satuan']?.toString() ?? '';

                if (bahanStr.isNotEmpty) {
                  final bahanList = bahanStr.split(',');
                  final jumlahList = jumlahStr.split(',');
                  final satuanList = satuanStr.split(',');

                  List<Map<String, dynamic>> bahanBakuArray = [];
                  for (int i = 0; i < bahanList.length; i++) {
                    if (bahanList[i].trim().isNotEmpty) {
                      bahanBakuArray.add({
                        'nama_bahan': bahanList[i].trim(),
                        'jumlah': i < jumlahList.length ? jumlahList[i].trim() : '0',
                        'unit': i < satuanList.length ? satuanList[i].trim() : 'pcs',
                        'id_bahan': '',
                      });
                    }
                  }

                  transformedItem['bahan_baku'] = bahanBakuArray;
                }
              }

              if (item.containsKey('harga_jual') && !item.containsKey('harga')) {
                transformedItem['harga'] = item['harga_jual'];
              }

              return MenuModel.fromJson(transformedItem);
            } catch (e) {
              return MenuModel(
                id: item['id']?.toString() ??
                    item['_id']?.toString() ??
                    'fallback_${DateTime.now().millisecondsSinceEpoch}',
                kode_menu: item['kode_menu']?.toString() ?? 'ERR',
                nama_menu: item['nama_menu']?.toString() ?? 'Unknown Item',
                kategori: item['kategori']?.toString() ?? 'Unknown',
                harga: item['harga']?.toString() ?? '0',
                stok: item['stok']?.toString() ?? '0',
                bahan_baku: [],
                foto_menu: item['foto_menu']?.toString() ?? '',
                barcode: item['barcode']?.toString() ?? '',
              );
            }
          }).toList();

          final categories = loadedMenus
              .map((m) => m.kategori ?? '')
              .where((cat) => cat.isNotEmpty && cat != 'null')
              .toSet()
              .toList();

          loadedCategories = ['Semua'] + categories;

        } catch (e) {
          _showToast("Format data menu tidak valid", isSuccess: false);
        }
      } else {
        _showToast("Tidak ada data menu tersedia", isSuccess: false);
      }

      final bahanResponse = await _dataService.selectAll(token, project, 'bahan_baku', appid);
      List<BahanBakuModel> loadedBahanBaku = [];

      if (bahanResponse.isNotEmpty && bahanResponse != '[]' && bahanResponse != 'null') {
        try {
          final decoded = json.decode(bahanResponse);
          List<dynamic> bahanDataList = [];

          if (decoded is Map && decoded.containsKey('data')) {
            bahanDataList = decoded['data'] as List<dynamic>;
          } else if (decoded is List) {
            bahanDataList = decoded;
          }

          loadedBahanBaku = bahanDataList
              .map((j) => BahanBakuModel.fromJson(j))
              .toList();
        } catch (e) {}
      }

      if (mounted) {
        setState(() {
          _menuList = loadedMenus;
          _bahanBakuList = loadedBahanBaku;
          _categories = loadedCategories;
        });
      }

    } catch (e) {
      _showToast("Gagal memuat data: $e", isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _parseHarga(String hargaStr) {
    if (hargaStr.isEmpty) return 0.0;

    try {
      String cleaned = hargaStr.replaceAll(RegExp(r'[^0-9.,]'), '');
      cleaned = cleaned.replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  List<MenuModel> _getFilteredMenus() {
    var filtered = _menuList;

    if (_selectedCategory != 'Semua') {
      filtered = filtered.where((menu) => menu.kategori == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filtered = filtered.where((menu) =>
      menu.nama_menu.toLowerCase().contains(searchLower) ||
          menu.kode_menu.toLowerCase().contains(searchLower)
      ).toList();
    }

    return filtered;
  }

  void _addToCart(MenuModel menu) {
    if (!_cekStokBahanBaku(menu, 1)) {
      _showToast("Stok bahan baku tidak mencukupi", isSuccess: false);
      return;
    }

    final existingIndex = _cartItems.indexWhere((item) => item.menu.id == menu.id);

    if (existingIndex != -1) {
      setState(() {
        _cartItems[existingIndex] = CartItem(
          menu: menu,
          quantity: _cartItems[existingIndex].quantity + 1,
        );
      });
    } else {
      setState(() {
        _cartItems.add(CartItem(
          menu: menu,
          quantity: 1,
        ));
      });
    }

    _calculateTotal();
    _showToast("✓ ${menu.nama_menu} ditambahkan", isSuccess: true);
  }

  bool _cekStokBahanBaku(MenuModel menu, int tambahanQuantity) {
    try {
      final bahanDetails = menu.bahan_baku;

      if (bahanDetails.isEmpty) {
        return true;
      }

      for (var bahan in bahanDetails) {
        final nama_bahan = bahan.nama_bahan;
        if (nama_bahan.isEmpty) continue;

        final jumlahPerMenu = double.tryParse(bahan.jumlah) ?? 0.0;
        final totalKebutuhan = jumlahPerMenu * tambahanQuantity;

        final bahanBaku = _bahanBakuList.firstWhere(
              (b) => b.nama_bahan.toLowerCase() == nama_bahan.toLowerCase(),
          orElse: () => BahanBakuModel.fromJson({}),
        );

        if (bahanBaku.id.isEmpty) continue;

        final stokTersedia = double.tryParse(bahanBaku.stok_tersedia ?? '0') ?? 0.0;

        double totalDiKeranjang = 0.0;
        for (var item in _cartItems) {
          for (var bahanItem in item.menu.bahan_baku) {
            if (bahanItem.nama_bahan.toLowerCase() == nama_bahan.toLowerCase()) {
              totalDiKeranjang += (double.tryParse(bahanItem.jumlah) ?? 0.0) * item.quantity;
              break;
            }
          }
        }

        totalDiKeranjang += totalKebutuhan;

        if (stokTersedia < totalDiKeranjang) {
          _showToast("Stok $nama_bahan tidak mencukupi (tersedia: $stokTersedia ${bahan.unit})", isSuccess: false);
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
    _calculateTotal();
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(index);
      return;
    }

    final item = _cartItems[index];
    final deltaQuantity = newQuantity - item.quantity;

    if (deltaQuantity > 0 && !_cekStokBahanBaku(item.menu, deltaQuantity)) {
      return;
    }

    setState(() {
      _cartItems[index] = CartItem(
        menu: item.menu,
        quantity: newQuantity,
      );
    });

    _calculateTotal();
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in _cartItems) {
      final harga = _parseHarga(item.menu.harga);
      total += harga * item.quantity;
    }

    setState(() {
      _totalHarga = total;
    });
  }

  Future<void> _prosesPembayaran() async {
    if (_cartItems.isEmpty) {
      _showToast("Keranjang kosong", isSuccess: false);
      return;
    }

    if (_namaPemesanController.text.isEmpty) {
      _showToast("Nama pemesan harus diisi", isSuccess: false);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final invoice = _generateInvoice();

      for (var cartItem in _cartItems) {
        await _kurangiStokBahanBaku(cartItem.menu, cartItem.quantity);
      }

      await _refreshBahanBakuData();

      final now = DateTime.now();
      final formattedTanggal = _formatTanggal(now);
      final formattedMenu = _formatMenuMultiLine();

      final result = await _dataService.insertStokKeluar(
        appid: appid,
        invoice: invoice,
        namaPemesanan: _namaPemesanController.text,
        noMeja: _noMejaController.text.isNotEmpty ? _noMejaController.text : '-',
        tanggal: formattedTanggal,
        menu: formattedMenu,
        catatan: _catatanController.text.isNotEmpty ? _catatanController.text : '-',
        totalHarga: _totalHarga.toString(),
      );

      // TAMPILKAN DIALOG DULU
      _showTransaksiBerhasilDialog(invoice);
      _showToast("✅ Transaksi berhasil! Invoice: $invoice", isSuccess: true);

      // RESET FORM SETELAHNYA (tapi perlu delay sedikit)
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _resetForm();
        }
      });

    } catch (e) {
      _showToast("Gagal memproses pembayaran: $e", isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _formatTanggal(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _formatMenuMultiLine() {
    if (_cartItems.isEmpty) return '-';

    return _cartItems
        .map((item) => '${item.menu.nama_menu} x${item.quantity}')
        .join('<br>');
  }

  Future<void> _kurangiStokBahanBaku(MenuModel menu, int quantity) async {
    try {
      for (var bahan in menu.bahan_baku) {
        final namaBahan = bahan.nama_bahan;
        if (namaBahan.isEmpty) continue;

        final bahanIndex = _bahanBakuList.indexWhere(
              (b) => b.nama_bahan.toLowerCase() == namaBahan.toLowerCase(),
        );

        if (bahanIndex == -1) continue;

        final bahanBaku = _bahanBakuList[bahanIndex];
        final jumlahPerMenu = double.tryParse(bahan.jumlah) ?? 0.0;
        final totalPengurangan = jumlahPerMenu * quantity;
        final stokLama = double.tryParse(bahanBaku.stok_tersedia) ?? 0.0;
        final stokBaru = stokLama - totalPengurangan;

        if (stokBaru < 0) {
          throw Exception('Stok $namaBahan tidak mencukupi');
        }

        bool updateSuccess = false;

        if (bahanBaku.id.isNotEmpty && bahanBaku.id != '') {
          final result = await _dataService.updateId(
            'stok_tersedia',
            stokBaru.toString(),
            token,
            project,
            'bahan_baku',
            appid,
            bahanBaku.id,
          );

          if (result == true) {
            updateSuccess = true;
          }
        }

        if (!updateSuccess) {
          try {
            await _dataService.updateWhere(
              'nama_bahan',
              bahanBaku.nama_bahan,
              'stok_tersedia',
              stokBaru.toString(),
              token,
              project,
              'bahan_baku',
              appid,
            );
            updateSuccess = true;
          } catch (e) {}
        }

        if (!updateSuccess) {
          throw Exception('Gagal update stok di database untuk $namaBahan');
        }

        if (mounted) {
          setState(() {
            _bahanBakuList[bahanIndex] = BahanBakuModel(
              id: bahanBaku.id,
              foto_bahan: bahanBaku.foto_bahan,
              nama_bahan: bahanBaku.nama_bahan,
              unit: bahanBaku.unit,
              gross_qty: bahanBaku.gross_qty,
              harga_per_gross: bahanBaku.harga_per_gross,
              harga_per_unit: bahanBaku.harga_per_unit,
              stok_tersedia: stokBaru.toString(),
              stok_minimal: bahanBaku.stok_minimal,
              estimasi_umur: bahanBaku.estimasi_umur,
              tanggal_masuk: bahanBaku.tanggal_masuk,
              tanggal_kadaluarsa: bahanBaku.tanggal_kadaluarsa,
              kategori: bahanBaku.kategori,
              tempat_penyimpanan: bahanBaku.tempat_penyimpanan,
              catatan: bahanBaku.catatan,
            );
          });
        }
      }

    } catch (e) {
      throw Exception('Gagal mengurangi stok: $e');
    }
  }

  Future<void> _refreshBahanBakuData() async {
    try {
      final bahanResponse = await _dataService.selectAll(token, project, 'bahan_baku', appid);

      if (bahanResponse.isNotEmpty && bahanResponse != '[]' && bahanResponse != 'null') {
        final decoded = json.decode(bahanResponse);
        List<dynamic> bahanDataList = [];

        if (decoded is Map && decoded.containsKey('data')) {
          bahanDataList = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          bahanDataList = decoded;
        }

        final refreshedList = bahanDataList.map<BahanBakuModel>((item) {
          Map<String, dynamic> itemMap = {};

          if (item is Map) {
            item.forEach((key, value) {
              if (key is String) {
                itemMap[key] = value;
              } else {
                itemMap[key.toString()] = value;
              }
            });
          }

          return BahanBakuModel(
            id: itemMap['_id']?.toString() ?? '',
            foto_bahan: itemMap['foto_bahan']?.toString() ?? '',
            nama_bahan: itemMap['nama_bahan']?.toString() ?? '',
            unit: itemMap['unit']?.toString() ?? '',
            gross_qty: itemMap['gross_qty']?.toString() ?? '',
            harga_per_gross: itemMap['harga_per_gross']?.toString() ?? '',
            harga_per_unit: itemMap['harga_per_unit']?.toString() ?? '',
            stok_tersedia: itemMap['stok_tersedia']?.toString() ?? '',
            stok_minimal: itemMap['stok_minimal']?.toString() ?? '',
            estimasi_umur: itemMap['estimasi_umur']?.toString() ?? '',
            tanggal_masuk: itemMap['tanggal_masuk']?.toString() ?? '',
            tanggal_kadaluarsa: itemMap['tanggal_kadaluarsa']?.toString() ?? '',
            kategori: itemMap['kategori']?.toString() ?? '',
            tempat_penyimpanan: itemMap['tempat_penyimpanan']?.toString() ?? '',
            catatan: itemMap['catatan']?.toString() ?? '',
          );
        }).toList();

        if (mounted) {
          setState(() {
            _bahanBakuList = refreshedList;
          });
        }
      }
    } catch (e) {}
  }

  void _showTransaksiBerhasilDialog(String invoice) {
    // **SIMPAN DATA CART SEBELUM DIALOG DITUTUP**
    final List<Map<String, dynamic>> savedCartItems = _cartItems.map((item) {
      return {
        'nama_menu': item.menu.nama_menu ?? 'Item',
        'quantity': item.quantity,
        'subtotal': _parseHarga(item.menu.harga) * item.quantity,
      };
    }).toList();

    final String savedNamaPemesan = _namaPemesanController.text;
    final String savedNoMeja = _noMejaController.text.isNotEmpty ? _noMejaController.text : '-';
    final String savedCatatan = _catatanController.text.isNotEmpty ? _catatanController.text : '-';
    final double savedTotalHarga = _totalHarga;
    final String savedUserId = _userId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 30),
            SizedBox(width: 10),
            Text('Transaksi Berhasil', style: AppTextStyles.headlineMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: $invoice', style: AppTextStyles.bodyMedium),
            SizedBox(height: 10),
            Text('Total: Rp ${_formatNumber(savedTotalHarga)}',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Text('Jumlah Item: ${savedCartItems.length}', style: AppTextStyles.bodySmall),
            SizedBox(height: 5),
            Text('Pelanggan: $savedNamaPemesan', style: AppTextStyles.bodySmall),
            SizedBox(height: 10),
            Text('Terima kasih atas pembeliannya!', style: AppTextStyles.bodySmall),
          ],
        ),
        actions: [
          // **PERBAIKI: Hapus _resetForm() dari sini**
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog saja
              // **TUNDA reset form setelah dialog ditutup**
              Future.delayed(Duration(milliseconds: 100), () {
                if (mounted) {
                  _resetForm();
                }
              });
            },
            child: Text('OK', style: TextStyle(color: AppColors.primary)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog

              // **GUNAKAN DATA YANG DISIMPAN, BUKAN DATA LANGSUNG DARI CONTROLLER**
              final transaksiData = {
                'no_transaksi': invoice,
                'nama_pemesan': savedNamaPemesan,
                'no_meja': savedNoMeja,
                'items': savedCartItems, // Gunakan savedCartItems
                'total_harga': savedTotalHarga,
                'catatan': savedCatatan,
                'tanggal': DateTime.now().toString(),
              };

              // **DEBUG: CETAK DATA UNTUK VERIFIKASI**
              print('=== DEBUG: DATA TRANSAKSI UNTUK STRUK ===');
              print('Invoice: $invoice');
              print('Nama Pemesan: $savedNamaPemesan');
              print('Jumlah Items: ${savedCartItems.length}');
              for (var i = 0; i < savedCartItems.length; i++) {
                print('  Item $i: ${savedCartItems[i]['nama_menu']} x${savedCartItems[i]['quantity']} = Rp ${savedCartItems[i]['subtotal']}');
              }
              print('Total: Rp $savedTotalHarga');
              print('User ID: $savedUserId');
              print('=========================================');

              // **NAVIGASI TANPA THEN CALLBACK**
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StrukPage(
                    transaksi: transaksiData,
                    userId: savedUserId,
                  ),
                ),
              );

              // **RESET FORM SETELAH NAVIGASI (tanpa delay)**
              Future.delayed(Duration(milliseconds: 300), () {
                if (mounted) {
                  _resetForm();
                }
              });
            },
            child: Text('Cetak Struk'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _cartItems.clear();
      _totalHarga = 0.0;
      _namaPemesanController.clear();
      _noMejaController.clear();
      _catatanController.clear();
    });
  }

  Widget _buildMenuCard(MenuModel menu) {
    final harga = _parseHarga(menu.harga);
    final stokMenu = int.tryParse(menu.stok) ?? 0;
    final bool isOutOfStock = stokMenu <= 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.all(6),
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => _addToCart(menu),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 180,
          child: Stack(
            children: [
              // Background gradient/image
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: menu.foto_menu != null && menu.foto_menu!.isNotEmpty
                      ? Image.network(
                    menu.foto_menu!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultBackground(menu);
                    },
                  )
                      : _buildDefaultBackground(menu),
                ),
              ),

              // Gradient overlay untuk teks lebih readable
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Konten utama
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bagian atas: Badge dan kategori
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Kode menu dengan glassmorphism effect
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            menu.kode_menu,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Kategori dengan warna sesuai jenis (MENGUNAKAN APPCOLORS)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(menu.kategori ?? '').withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            menu.kategori ?? 'Menu',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Spacer(),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama menu dengan shadow
                        Text(
                          menu.nama_menu,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 6),

                        // Harga dan stok
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Harga dengan glowing effect (MENGUNAKAN APPCOLORS)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                'Rp ${_formatNumber(harga)}',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),

                            // Stok indicator (MENGUNAKAN APPCOLORS)
                            if (stokMenu > 0)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.inventory, size: 12, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text(
                                      '$stokMenu',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Floating Add Button (MENGUNAKAN APPCOLORS)
              if (!isOutOfStock)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                      gradient: AppColors.primaryGradient, // MENGGUNAKAN GRADIENT DARI APPCOLORS
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBackground(MenuModel menu) {
    final categoryColor = _getCategoryColor(menu.kategori ?? '');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withOpacity(0.7),
            categoryColor.withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 50,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  // MENGUBAH KE APPCOLORS
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return AppColors.categoryFood;
      case 'minuman':
        return AppColors.categoryDrink;
      case 'dessert':
        return AppColors.categoryDessert;
      case 'snack':
        return AppColors.categorySnack;
      default:
        return AppColors.primary; // MENGGUNAKAN PRIMARY COLOR
    }
  }

  Widget _buildCartItem(CartItem item, int index) {
    final harga = _parseHarga(item.menu.harga);
    final subtotal = harga * item.quantity;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface, // MENGGUNAKAN SURFACE COLOR
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atas: Informasi menu
            Row(
              children: [
                // Quantity indicator (MENGUNAKAN APPCOLORS)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient, // MENGGUNAKAN GRADIENT
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Menu info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.menu.nama_menu,
                        style: AppTextStyles.bodyMedium.copyWith( // MENGGUNAKAN TEXT STYLES
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.card, // MENGGUNAKAN CARD COLOR
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Kode: ${item.menu.kode_menu}',
                                style: AppTextStyles.labelSmall.copyWith( // MENGGUNAKAN TEXT STYLES
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (item.menu.bahan_baku.isNotEmpty) ...[
                              SizedBox(width: 6),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.menu.bahan_baku.length} bahan',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Harga per item dan subtotal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${_formatNumber(subtotal)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success, // MENGGUNAKAN SUCCESS COLOR
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(harga)}/pcs',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12),

            // Baris bawah: Tombol kontrol quantity dan delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity controls (MENGUNAKAN APPCOLORS)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _updateQuantity(index, item.quantity - 1),
                        icon: Icon(Icons.remove, size: 16),
                        color: AppColors.textPrimary,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(minWidth: 40, minHeight: 36),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Center(
                          child: Text(
                            '${item.quantity}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _updateQuantity(index, item.quantity + 1),
                        icon: Icon(Icons.add, size: 16),
                        color: AppColors.textPrimary,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(minWidth: 40, minHeight: 36),
                      ),
                    ],
                  ),
                ),

                // Delete button (MENGUNAKAN APPCOLORS)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    onPressed: () => _removeFromCart(index),
                    icon: Icon(Icons.delete_outline, size: 20),
                    color: AppColors.danger,
                    tooltip: 'Hapus item',
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Pesanan',
            style: AppTextStyles.headlineMedium, // MENGGUNAKAN TEXT STYLES
          ),
          SizedBox(height: 16),

          TextField(
            controller: _namaPemesanController,
            decoration: InputDecoration(
              labelText: 'Nama Pemesan*',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(Icons.person, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),

          SizedBox(height: 12),

          TextField(
            controller: _noMejaController,
            decoration: InputDecoration(
              labelText: 'Nomor Meja',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(Icons.table_restaurant, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
          ),

          SizedBox(height: 12),

          TextField(
            controller: _catatanController,
            decoration: InputDecoration(
              labelText: 'Catatan (Opsional)',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(Icons.note, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: EdgeInsets.only(right: 8, left: index == 0 ? 0 : 0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'Semua';
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary, // MENGGUNAKAN PRIMARY COLOR
              labelStyle: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  void _showToast(String message, {bool isSuccess = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isSuccess ? AppColors.success : AppColors.danger, // MENGGUNAKAN APPCOLORS
      textColor: Colors.white,
      fontSize: 14,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMenus = _getFilteredMenus();

    return Scaffold(
      backgroundColor: AppColors.background, // MENGGUNAKAN BACKGROUND COLOR
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text('Memuat data...', style: AppTextStyles.bodyMedium),
          ],
        ),
      )
          : LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1000) {
            return _buildDesktopLayout(filteredMenus);
          } else {
            return _buildMobileLayout(filteredMenus);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(List<MenuModel> filteredMenus) {
    return Row(
      children: [
        // Left Panel - Menu
        Expanded(
          flex: 3,
          child: Container(
            color: AppColors.background,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari menu atau kode...',
                          hintStyle: TextStyle(color: AppColors.textDisabled),
                          prefixIcon: Icon(Icons.search, color: AppColors.primary),
                          filled: true,
                          fillColor: AppColors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),

                      SizedBox(height: 12),

                      // Categories
                      Container(
                        height: 40,
                        child: _buildCategoryFilter(),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8),

                // Menu Grid
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: filteredMenus.length,
                      itemBuilder: (context, index) {
                        return _buildMenuCard(filteredMenus[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Divider
        Container(
          width: 1,
          color: AppColors.border,
        ),

        // Right Panel - Cart & Form
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  // Form Input
                  _buildFormInput(),

                  SizedBox(height: 16),

                  // Cart Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Cart Header
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Keranjang Pesanan',
                              style: AppTextStyles.headlineMedium,
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_cartItems.length} item',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Cart Items
                        _cartItems.isEmpty
                            ? Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: AppColors.textDisabled,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Keranjang Kosong',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textDisabled,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                            : Column(
                          children: _cartItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return _buildCartItem(item, index);
                          }).toList(),
                        ),

                        SizedBox(height: 20),

                        // Total Summary
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Item:', style: AppTextStyles.bodyMedium),
                                  Text('${_cartItems.length}', style: AppTextStyles.bodyMedium),
                                ],
                              ),
                              SizedBox(height: 8),
                              Divider(color: AppColors.border),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Harga:', style: AppTextStyles.headlineSmall),
                                  Text(
                                    'Rp ${_formatNumber(_totalHarga)}',
                                    style: AppTextStyles.displaySmall.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // Action Buttons (MENGUNAKAN APPCOLORS)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _cartItems.isEmpty ? null : () {
                                  setState(() {
                                    _cartItems.clear();
                                    _totalHarga = 0.0;
                                  });
                                  _showToast("Keranjang dibersihkan");
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white, // Teks PUTIH agar terlihat
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text('Bersihkan', style: AppTextStyles.buttonMedium),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _prosesPembayaran,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isProcessing
                                    ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.payment, size: 20),
                                    SizedBox(width: 8),
                                    Text('Proses Pembayaran', style: AppTextStyles.buttonMedium),
                                  ],
                                ),
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
      ],
    );
  }

  Widget _buildMobileLayout(List<MenuModel> filteredMenus) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(10),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 20),
                        SizedBox(width: 6),
                        Text('Menu', style: AppTextStyles.labelMedium),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart, size: 20),
                        SizedBox(width: 6),
                        Text('Pesanan', style: AppTextStyles.labelMedium),
                      ],
                    ),
                  ),
                ],
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Tab Menu
            Column(
              children: [
                // Search & Filter
                Container(
                  padding: EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Cari menu...',
                          hintStyle: TextStyle(color: AppColors.textDisabled),
                          prefixIcon: Icon(Icons.search, color: AppColors.primary),
                          filled: true,
                          fillColor: AppColors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 40,
                        child: _buildCategoryFilter(),
                      ),
                    ],
                  ),
                ),

                // Menu Grid
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: filteredMenus.length,
                      itemBuilder: (context, index) {
                        return _buildMenuCard(filteredMenus[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Tab Pesanan
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Cart Items
                  _cartItems.isEmpty
                      ? Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 100,
                          color: AppColors.textDisabled,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Keranjang Kosong',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textDisabled,
                          ),
                        ),
                        Text(
                          'Pilih menu dari tab Menu',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Column(
                    children: [
                      ..._cartItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _buildCartItem(item, index);
                      }),
                      SizedBox(height: 20),

                      // Form Input
                      _buildFormInput(),

                      SizedBox(height: 20),

                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Item:', style: AppTextStyles.bodyMedium),
                                Text('${_cartItems.length}', style: AppTextStyles.bodyMedium),
                              ],
                            ),
                            SizedBox(height: 8),
                            Divider(color: AppColors.border),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Harga:', style: AppTextStyles.headlineMedium),
                                Text(
                                  'Rp ${_formatNumber(_totalHarga)}',
                                  style: AppTextStyles.displaySmall.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _cartItems.isEmpty ? null : () {
                                setState(() {
                                  _cartItems.clear();
                                  _totalHarga = 0.0;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.danger,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: AppColors.danger),
                                ),
                              ),
                              child: Text('Bersihkan', style: AppTextStyles.buttonMedium),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _prosesPembayaran,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isProcessing
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text('Proses Pembayaran', style: AppTextStyles.buttonMedium),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class untuk cart item
class CartItem {
  final MenuModel menu;
  int quantity;

  CartItem({
    required this.menu,
    required this.quantity,
  });
}