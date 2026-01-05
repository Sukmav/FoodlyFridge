import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../restapi.dart';
import '../config.dart';
import '../model/bahan_baku_model.dart';
import 'menu_detail_page.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final DataService _dataService = DataService();
  List<Map<String, dynamic>> _menuList = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMenuPage(),
      ),
    ).then((_) {
      _loadMenu(); // Reload menu setelah kembali
    });
  }

  List<Map<String, dynamic>> get _filteredMenuList {
    if (_searchQuery.isEmpty && _selectedCategory == null) {
      return _menuList;
    }

    return _menuList.where((menu) {
      final matchesSearch = _searchQuery.isEmpty ||
          (menu['nama_menu']?.toString().toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) ||
          (menu['id_menu']?.toString().toLowerCase() ?? '').contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == null ||
          (menu['kategori']?.toString().toLowerCase() ?? '') == _selectedCategory!.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get _categories {
    final categories = _menuList.map((menu) => menu['kategori']?.toString() ?? '').toSet().toList();
    categories.removeWhere((cat) => cat.isEmpty);
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats in a subtle pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_menuList.length} Menu Tersedia',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Modern Search Bar with Category in one row
                  Row(
                    children: [
                      Expanded(

                        //bagian search bar
                        child: Container(
                          height: 49,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cari menu...',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary.withOpacity(0.6),
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 16, right: 12),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: AppColors.primary, // Gunakan AppColors.primary
                                  size: 24,
                                ),
                              ),

                              border: InputBorder.none,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.primary, // Gunakan AppColors.primary
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      
                      //Bagian Kategori
                      if (_categories.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 56,
                          height: 49,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.filter_list_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            onSelected: (String? value) {
                              setState(() {
                                _selectedCategory = value == 'all' ? null : value;
                              });
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem<String>(
                                  value: 'all',
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Semua',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                ..._categories.map((category) {
                                  return PopupMenuItem<String>(
                                    value: category,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(category),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          category,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ];
                            },
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Active Filter Badge
                  if (_selectedCategory != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(_selectedCategory!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getCategoryColor(_selectedCategory!).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Kategori: $_selectedCategory',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _getCategoryColor(_selectedCategory!),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = null;
                              });
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: _getCategoryColor(_selectedCategory!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Menu List dengan SingleChildScrollView untuk menghindari overflow
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Memuat menu...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredMenuList.isEmpty
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.15),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.restaurant_menu_outlined,
                                    size: 70,
                                    color: AppColors.primary.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  _searchQuery.isEmpty && _selectedCategory == null
                                      ? 'Belum Ada Menu'
                                      : 'Menu Tidak Ditemukan',
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    _searchQuery.isEmpty && _selectedCategory == null
                                        ? 'Tambahkan menu pertama Anda untuk memulai'
                                        : 'Coba cari dengan kata kunci lain atau pilih kategori berbeda',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 20, // LEBIH BESAR untuk card yang lebih tinggi
                                    childAspectRatio: 0.75, // Ratio yang lebih proporsional
                                  ),
                                  itemCount: _filteredMenuList.length,
                                  itemBuilder: (context, index) {
                                    final menu = _filteredMenuList[index];
                                    return _buildMenuCard(menu);
                                  },
                                ),
                                const SizedBox(height: 100), // Spacer untuk FAB
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),

      // TAMBAH bottomNavigationBar untuk tombol "Tambah Menu"
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.3))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _showAddMenuForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, // Gunakan AppColors.primary
            foregroundColor: AppColors.textWhite,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 24),
              const SizedBox(width: 12),
              Text(
                'Tambah Menu',
                style: AppTextStyles.buttonLarge.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> menu) {
    final harga = double.tryParse(menu['harga_jual']?.toString() ?? '0') ?? 0;
    final category = menu['kategori']?.toString() ?? '';
    final namaMenu = menu['nama_menu']?.toString() ?? '';
    final idMenu = menu['id_menu']?.toString() ?? '';
    final categoryColor = _getCategoryColor(category); // TAMBAHKAN INI
    final categoryGradient = _getCategoryGradient(category);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetailMenu(menu),
        child: SizedBox(
          width: double.infinity,
          height: 265, // TINGKATKAN TINGGI CARD (dari 200 ke 220)
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Container - dengan tinggi yang lebih proporsional
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    gradient: categoryGradient,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image Background
                      menu['foto_menu'] != null && menu['foto_menu'].toString().isNotEmpty
                          ? Image.network(
                              menu['foto_menu'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.restaurant_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.restaurant_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                      
                      // Category Badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            category,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      
                      // Price Tag
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppColors.priceTagGradientVibrant,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomRight: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _formatNumber(harga),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content Container - PERBAIKI LAYOUT
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Nama Menu
                        Text(
                          namaMenu,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Kode Menu dan Icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kode: $idMenu',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            // Barcode Icon
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Icon(
                                Icons.qr_code_2_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    return 'Rp${number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return AppColors.categoryFood; // Makanan: Color(0xFF8B5FBF)
      case 'minuman':
        return AppColors.categoryDrink; // Minuman: Color(0xFF2196F3)
      case 'dessert':
        return AppColors.categoryDessert; // Dessert: Color(0xFFE91E63)
      case 'snack':
        return AppColors.categorySnack; // Snack: Color(0xFFFF9800)
      default:
        return AppColors.primary; // Default: Color(0xFF7C4585)
    }
  }

  LinearGradient _getCategoryGradient(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return AppColors.categoryFoodGradient;
      case 'minuman':
        return AppColors.categoryDrinkGradient;
      case 'dessert':
        return AppColors.categoryDessertGradient;
      case 'snack':
        return AppColors.categorySnackGradient;
      default:
        return AppColors.primaryGradient;
    }
  }
}

class AddMenuPage extends StatefulWidget {
  const AddMenuPage({super.key});

  @override
  State<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {
  final DataService _dataService = DataService();

  final _kodeMenuController = TextEditingController();
  final _namaMenuController = TextEditingController();
  String? _selectedKategori;
  final _hargaController = TextEditingController();
  final _totalRecipeCostController = TextEditingController();
  final _foodCostController = TextEditingController();
  final GlobalKey _barcodeKey = GlobalKey();
  bool _showBarcode = false;

  List<BahanBakuModel> _availableBahanBaku = [];
  bool _isLoadingBahanBaku = false;
  List<Map<String, dynamic>> _bahanBakuList = [];

  double _totalRecipeCost = 0.0;
  double _foodCostPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBahanBaku();
    _kodeMenuController.addListener(() {
      setState(() {
        _showBarcode = _kodeMenuController.text.isNotEmpty;
      });
    });
    _hargaController.addListener(_calculateFoodCost);
  }

  @override
  void dispose() {
    _kodeMenuController.dispose();
    _namaMenuController.dispose();
    _hargaController.dispose();
    _totalRecipeCostController.dispose();
    _foodCostController.dispose();
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
    if (_hargaController.text.isNotEmpty && _totalRecipeCost > 0) {
      final harga = double.tryParse(_hargaController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      if (harga > 0) {
        setState(() {
          _foodCostPercentage = (_totalRecipeCost / harga) * 100;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Menu',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Image Section
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 50,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload Foto',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Basic Information
            _buildSectionHeader('Informasi Utama'),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _kodeMenuController,
              label: 'Kode Menu',
              hint: 'Masukkan kode menu',
              icon: Icons.qr_code_2_rounded,
            ),

            const SizedBox(height: 16),

            // Barcode Preview
            if (_showBarcode && _kodeMenuController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _kodeMenuController.text,
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
              label: 'Nama Menu',
              hint: 'Masukkan nama menu',
              icon: Icons.restaurant_rounded,
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

            _buildTextField(
              controller: _hargaController,
              label: 'Harga Jual',
              hint: 'Masukkan harga jual',
              keyboardType: TextInputType.number,
              icon: Icons.attach_money_rounded,
            ),

            const SizedBox(height: 30),

            // Calculation Summary
            _buildSectionHeader('Ringkasan Perhitungan'),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: 'Total Recipe Cost',
                    value: 'Rp${_formatNumber(_totalRecipeCost)}',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: 'Food Cost',
                    value: '${_foodCostPercentage.toStringAsFixed(1)}%',
                    color: _foodCostPercentage > 40 ? AppColors.danger : AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Bahan Baku Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Daftar Bahan Baku'),
                ElevatedButton.icon(
                  onPressed: _addBahanBaku,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingBahanBaku)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Memuat bahan baku...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_availableBahanBaku.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada bahan baku',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambahkan bahan baku terlebih dahulu',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textDisabled,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._bahanBakuList.asMap().entries.map((entry) {
                return _buildBahanBakuCard(entry.key);
              }),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _saveMenu,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
          ),
          child: Text(
            'Simpan Menu',
            style: AppTextStyles.buttonLarge.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveMenu() async {
    if (_kodeMenuController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Kode menu harus diisi!",
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
      return;
    }

    if (_namaMenuController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Nama menu harus diisi!",
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
      return;
    }

    if (_selectedKategori == null) {
      Fluttertoast.showToast(
        msg: "Kategori harus dipilih!",
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
      return;
    }

    if (_hargaController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Harga jual harus diisi!",
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
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

    try {
      Fluttertoast.showToast(
        msg: "Menyimpan menu...",
        backgroundColor: AppColors.info,
        textColor: Colors.white,
      );

      final result = await _dataService.insertMenu(
        appid,
        _kodeMenuController.text,
        _namaMenuController.text,
        '',
        _selectedKategori!,
        _hargaController.text,
        _kodeMenuController.text,
        bahanList.join(','),
        jumlahList.join(','),
        satuanList.join(','),
        biayaList.join(','),
        '',
      );

      print('Result insert menu: $result');

      Fluttertoast.showToast(
        msg: "Menu berhasil ditambahkan!",
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );

      Navigator.pop(context);

    } catch (e) {
      print('Error saving menu: $e');
      Fluttertoast.showToast(
        msg: "Gagal menyimpan menu: ${e.toString()}",
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDisabled,
            ),
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: AppColors.primary,
                    size: 22,
                  )
                : null,
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
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
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: 'Pilih kategori',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDisabled,
            ),
            prefixIcon: Icon(
              Icons.category_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBahanBakuCard(int index) {
    final item = _bahanBakuList[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
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
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
                onPressed: () => _removeBahanBaku(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<BahanBakuModel>(
            value: item['bahan'],
            decoration: InputDecoration(
              hintText: 'Pilih bahan baku',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDisabled,
              ),
              prefixIcon: Icon(
                Icons.shopping_basket_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: _availableBahanBaku.map((BahanBakuModel bahan) {
              return DropdownMenuItem<BahanBakuModel>(
                value: bahan,
                child: Text(
                  '${bahan.nama_bahan} (${bahan.unit})',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
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
                child: TextField(
                  controller: item['qtyController'],
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _calculateTotalRecipeCost(),
                  decoration: InputDecoration(
                    labelText: 'Jumlah',
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    item['unit'] ?? '-',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Biaya',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Rp${_formatNumber(item['cost'] ?? 0.0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}