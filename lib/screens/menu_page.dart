import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import '../restapi.dart';
import '../config.dart';
import '../model/bahan_baku_model.dart';
import 'menu_detail_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final DataService _dataService = DataService();
  List<Map<String, dynamic>> _menuList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== LOADING MENU ===');
      final response = await _dataService.selectAll(
        token,
        project,
        'menu',
        appid,
      );

      if (response == '[]' || response.isEmpty || response == 'null') {
        setState(() {
          _menuList = [];
          _isLoading = false;
        });
        return;
      }

      final dynamic decodedData = json.decode(response);
      List<dynamic> dataList;

      if (decodedData is Map && decodedData.containsKey('data')) {
        dataList = decodedData['data'] as List<dynamic>;
      } else if (decodedData is List) {
        dataList = decodedData;
      } else {
        dataList = [];
      }

      setState(() {
        _menuList = dataList.map((item) => Map<String, dynamic>.from(item)).toList();
        _isLoading = false;
      });

      print('Menu loaded: ${_menuList.length} items');

    } catch (e, stackTrace) {
      print('Error loading menu: $e');
      print('StackTrace: $stackTrace');

      setState(() {
        _menuList = [];
        _isLoading = false;
      });
    }
  }

  void _showAddMenuForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMenuForm(
        onMenuAdded: () {
          _loadMenu(); // Reload menu setelah menambah
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _menuList.isEmpty ? _buildEmptyState() : _buildMenuList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak Ada Menu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada menu yang ditambahkan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _showAddMenuForm,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Tambah Menu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8, // Diperbesar dari 0.75 untuk menghindari overflow
            ),
            itemCount: _menuList.length,
            itemBuilder: (context, index) {
              final menu = _menuList[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showDetailMenu(menu),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image
                      Expanded(
                        flex: 5, // Diperbesar dari 3 untuk lebih banyak ruang
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: menu['foto_menu'] != null && menu['foto_menu'].toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    menu['foto_menu'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.restaurant,
                                        color: Colors.green[700],
                                        size: 48,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.restaurant,
                                  color: Colors.green[700],
                                  size: 48,
                                ),
                        ),
                      ),

                      // Content
                      Expanded(
                        flex: 4, // Diperbesar dari 2 untuk lebih banyak ruang
                        child: Padding(
                          padding: const EdgeInsets.all(8), // Dikurangi dari 12 untuk menghemat ruang
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Diubah dari spaceBetween
                            children: [
                              // Nama menu
                              Text(
                                menu['nama_menu'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14, // Dikurangi dari 16
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),

                              // Kode Menu
                              Text(
                                'Kode Menu : ${menu['id_menu'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 11, // Dikurangi dari 12
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),

                              // Harga
                              Text(
                                'Harga: ${_formatNumber(double.tryParse(menu['harga_jual']?.toString() ?? '0') ?? 0)}',
                                style: const TextStyle(
                                  fontSize: 13, // Dikurangi dari 14
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _showAddMenuForm,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Tambah Menu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDetailMenu(Map<String, dynamic> menu) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuDetailPage(
          menu: menu,
          onMenuUpdated: () {
            _loadMenu();
          },
          onMenuDeleted: () {
            _loadMenu();
          },
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class AddMenuForm extends StatefulWidget {
  const AddMenuForm({super.key, this.onMenuAdded});

  final VoidCallback? onMenuAdded;

  @override
  State<AddMenuForm> createState() => _AddMenuFormState();
}

class _AddMenuFormState extends State<AddMenuForm> {
  final DataService _dataService = DataService();

  final _kodeMenuController = TextEditingController();
  final _namaMenuController = TextEditingController();
  String? _selectedKategori;
  final _hargaJualController = TextEditingController();
  final _totalRecipeCostController = TextEditingController();
  final _foodCostController = TextEditingController();
  final GlobalKey _barcodeKey = GlobalKey();
  bool _showBarcode = false;

  // Data bahan baku dari database
  List<BahanBakuModel> _availableBahanBaku = [];
  bool _isLoadingBahanBaku = false;

  // List bahan baku yang dipilih untuk menu
  List<Map<String, dynamic>> _bahanBakuList = [];

  double _totalRecipeCost = 0.0;
  double _foodCostPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBahanBaku();

    // Listen to kode menu changes to show barcode
    _kodeMenuController.addListener(() {
      setState(() {
        _showBarcode = _kodeMenuController.text.isNotEmpty;
      });
    });

    // Listen to harga jual changes to recalculate food cost
    _hargaJualController.addListener(_calculateFoodCost);
  }

  @override
  void dispose() {
    _kodeMenuController.dispose();
    _namaMenuController.dispose();
    _hargaJualController.dispose();
    _totalRecipeCostController.dispose();
    _foodCostController.dispose();

    // Dispose all qty controllers
    for (var item in _bahanBakuList) {
      item['qtyController']?.dispose();
    }

    super.dispose();
  }

  Future<void> _loadBahanBaku() async {
    setState(() {
      _isLoadingBahanBaku = true;
    });

    try {
      print('=== LOADING BAHAN BAKU ===');
      final response = await _dataService.selectAll(
        token,
        project,
        'bahan_baku',
        appid,
      );

      if (response == '[]' || response.isEmpty || response == 'null') {
        setState(() {
          _availableBahanBaku = [];
          _isLoadingBahanBaku = false;
        });
        return;
      }

      final dynamic decodedData = json.decode(response);
      List<dynamic> dataList;

      if (decodedData is Map && decodedData.containsKey('data')) {
        dataList = decodedData['data'] as List<dynamic>;
      } else if (decodedData is List) {
        dataList = decodedData;
      } else {
        dataList = [];
      }

      final newList = dataList.map((json) => BahanBakuModel.fromJson(json)).toList();

      setState(() {
        _availableBahanBaku = newList;
        _isLoadingBahanBaku = false;
      });

      print('Bahan baku loaded: ${_availableBahanBaku.length} items');

    } catch (e, stackTrace) {
      print('Error loading bahan baku: $e');
      print('StackTrace: $stackTrace');

      setState(() {
        _availableBahanBaku = [];
        _isLoadingBahanBaku = false;
      });
    }
  }

  void _addBahanBaku() {
    setState(() {
      _bahanBakuList.add({
        'bahan': null,
        'qtyController': TextEditingController(),
        'unit': '',
        'cost': 0.0,
      });
    });
  }

  void _removeBahanBaku(int index) {
    setState(() {
      _bahanBakuList[index]['qtyController']?.dispose();
      _bahanBakuList.removeAt(index);
      _calculateTotalRecipeCost();
    });
  }

  void _calculateTotalRecipeCost() {
    double total = 0.0;
    for (var item in _bahanBakuList) {
      if (item['bahan'] != null && item['qtyController'].text.isNotEmpty) {
        final BahanBakuModel bahan = item['bahan'];
        final qty = double.tryParse(item['qtyController'].text) ?? 0.0;
        final hargaUnit = double.tryParse(bahan.harga_per_unit) ?? 0.0;
        final cost = qty * hargaUnit;
        item['cost'] = cost;
        total += cost;
      }
    }

    setState(() {
      _totalRecipeCost = total;
      _totalRecipeCostController.text = 'Rp${_formatNumber(_totalRecipeCost)}';
      _calculateFoodCost();
    });
  }

  void _calculateFoodCost() {
    if (_hargaJualController.text.isNotEmpty && _totalRecipeCost > 0) {
      final hargaJual = double.tryParse(_hargaJualController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      if (hargaJual > 0) {
        setState(() {
          _foodCostPercentage = (_totalRecipeCost / hargaJual) * 100;
          _foodCostController.text = '${_foodCostPercentage.toStringAsFixed(1)}%';
        });
      }
    } else {
      setState(() {
        _foodCostPercentage = 0.0;
        _foodCostController.text = '0%';
      });
    }
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _downloadBarcode() async {
    try {
      // Get the render object from the key
      RenderRepaintBoundary? boundary = _barcodeKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        Fluttertoast.showToast(
          msg: "Gagal mengambil barcode",
          backgroundColor: Colors.red,
        );
        return;
      }

      // Capture the widget as an image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        Fluttertoast.showToast(
          msg: "Gagal mengonversi barcode",
          backgroundColor: Colors.red,
        );
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Get directory to save the file
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        Fluttertoast.showToast(
          msg: "Gagal mengakses direktori penyimpanan",
          backgroundColor: Colors.red,
        );
        return;
      }

      // Save the file
      final fileName = 'barcode_${_kodeMenuController.text}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      Fluttertoast.showToast(
        msg: "Barcode berhasil diunduh!\n$filePath",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Gagal mengunduh barcode: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Tambah Menu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Upload Gambar
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_circle,
                                    color: Colors.green[700],
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Informasi Utama
                      _buildSectionTitle('Informasi Utama'),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _kodeMenuController,
                        label: 'Kode Menu',
                        hint: 'Masukkan kode menu',
                      ),

                      const SizedBox(height: 16),

                      // Barcode Section
                      if (_showBarcode && _kodeMenuController.text.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300, width: 2),
                          ),
                          child: Column(
                            children: [
                              RepaintBoundary(
                                key: _barcodeKey,
                                child: Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      BarcodeWidget(
                                        barcode: Barcode.code128(),
                                        data: _kodeMenuController.text,
                                        width: 250,
                                        height: 100,
                                        drawText: false,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _kodeMenuController.text,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _downloadBarcode,
                                  icon: const Icon(Icons.download, color: Colors.white),
                                  label: const Text(
                                    'Unduh Barcode',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildTextField(
                        controller: _namaMenuController,
                        label: 'Nama menu',
                        hint: 'Masukkan nama menu',
                      ),

                      const SizedBox(height: 16),

                      _buildDropdownField(
                        label: 'Kategori',
                        value: _selectedKategori,
                        items: ['Makanan', 'Minuman', 'Dessert', 'Snack'],
                        onChanged: (value) {
                          setState(() {
                            _selectedKategori = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Harga Jual - Ditambahkan setelah kategori
                      _buildTextField(
                        controller: _hargaJualController,
                        label: 'Harga Jual',
                        hint: 'Masukkan harga jual',
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 30),

                      // Ringkasan Perhitungan
                      _buildSectionTitle('Ringkasan Perhitungan'),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _totalRecipeCostController,
                        label: 'Total Recipe Cost (otomatis)',
                        hint: 'Rp0',
                        enabled: false,
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _foodCostController,
                        label: 'Food Cost % (otomatis)',
                        hint: '0%',
                        enabled: false,
                      ),

                      const SizedBox(height: 30),

                      // Daftar Bahan Baku
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Daftar Bahan Baku'),
                          ElevatedButton.icon(
                            onPressed: _addBahanBaku,
                            icon: const Icon(Icons.add, size: 18, color: Colors.white),
                            label: const Text('Tambah Bahan', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_isLoadingBahanBaku)
                        const Center(child: CircularProgressIndicator())
                      else if (_availableBahanBaku.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Belum ada bahan baku. Silakan tambahkan bahan baku terlebih dahulu.',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ..._bahanBakuList.asMap().entries.map((entry) {
                          return _buildBahanBakuCard(entry.key);
                        }),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Submit Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveMenu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tambah',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveMenu() async {
    // Validasi input
    if (_kodeMenuController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Kode menu harus diisi!",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_namaMenuController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Nama menu harus diisi!",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_selectedKategori == null) {
      Fluttertoast.showToast(
        msg: "Kategori harus dipilih!",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_hargaJualController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Harga jual harus diisi!",
        backgroundColor: Colors.red,
      );
      return;
    }

    // Format data bahan baku
    List<String> bahanList = [];
    List<String> jumlahList = [];
    List<String> satuanList = [];
    List<String> biayaList = [];

    for (var item in _bahanBakuList) {
      if (item['bahan'] != null) {
        final BahanBakuModel bahan = item['bahan'];
        bahanList.add(bahan.nama_bahan);
        jumlahList.add(item['qtyController'].text);
        satuanList.add(bahan.unit);
        biayaList.add(item['cost'].toString());
      }
    }

    // Insert ke database
    try {
      Fluttertoast.showToast(
        msg: "Menyimpan menu...",
        backgroundColor: Colors.blue,
      );

      final result = await _dataService.insertMenu(
        appid,
        _kodeMenuController.text,
        _namaMenuController.text,
        '', // foto_menu (kosong untuk sementara)
        _selectedKategori ?? '',
        _hargaJualController.text,
        _kodeMenuController.text, // barcode sama dengan kode menu
        bahanList.join(','),
        jumlahList.join(','),
        satuanList.join(','),
        biayaList.join(','),
        '', // catatan (kosong)
      );

      print('Result insert menu: $result');

      Fluttertoast.showToast(
        msg: "Menu berhasil ditambahkan!",
        backgroundColor: Colors.green,
      );

      // Callback untuk reload data
      widget.onMenuAdded?.call();

      // Tutup dialog
      Navigator.pop(context);

    } catch (e) {
      print('Error saving menu: $e');
      Fluttertoast.showToast(
        msg: "Gagal menyimpan menu: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.orange[700],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: 'Pilih kategori',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBahanBakuCard(int index) {
    final item = _bahanBakuList[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
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
                'Bahan Baku ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeBahanBaku(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dropdown Bahan Baku
          DropdownButtonFormField<BahanBakuModel>(
            value: item['bahan'],
            decoration: InputDecoration(
              hintText: 'Pilih bahan baku',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _availableBahanBaku.map((BahanBakuModel bahan) {
              return DropdownMenuItem<BahanBakuModel>(
                value: bahan,
                child: Text(
                  '${bahan.nama_bahan} (${bahan.unit}) - Rp${bahan.harga_per_unit}',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (BahanBakuModel? value) {
              setState(() {
                item['bahan'] = value;
                item['unit'] = value?.unit ?? '';
                _calculateTotalRecipeCost();
              });
            },
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: item['qtyController'],
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _calculateTotalRecipeCost(),
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    labelStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    item['unit'] ?? '-',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    'Rp${_formatNumber(item['cost'] ?? 0.0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
