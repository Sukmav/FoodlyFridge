//lib/screens/menu_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../restapi.dart';
import '../config.dart';
import '../model/bahan_baku_model.dart';
import 'menu_detail_page.dart';
import 'add_menu_form.dart';
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
        _menuList = dataList
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });

      print('Menu loaded:  ${_menuList.length} items');
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
        builder: (context) => const AddMenuForm(onMenuAdded: null),
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
      final matchesSearch =
          _searchQuery.isEmpty ||
              (menu['nama_menu']?.toString().toLowerCase() ?? '').contains(
                _searchQuery.toLowerCase(),
              ) ||
              (menu['id_menu']?.toString().toLowerCase() ?? '').contains(
                _searchQuery.toLowerCase(),
              );

      final matchesCategory =
          _selectedCategory == null ||
              (menu['kategori']?.toString().toLowerCase() ?? '') ==
                  _selectedCategory!.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get _categories {
    final categories = _menuList
        .map((menu) => menu['kategori']?.toString() ?? '')
        .toSet()
        .toList();
    categories.removeWhere((cat) => cat.isEmpty);
    return categories;
  }

  // Helper method untuk menampilkan foto menu
  Widget _buildMenuImage(String? fotoMenu) {
    // Jika foto kosong atau null
    if (fotoMenu == null || fotoMenu.isEmpty) {
      return Container(
        decoration: BoxDecoration(gradient: _getCategoryGradient('default')),
        child: const Center(
          child: Icon(Icons.restaurant_rounded, size: 40, color: Colors.white),
        ),
      );
    }

    // Jika foto adalah URL (dimulai dengan http)
    if (fotoMenu.startsWith('http')) {
      return Image.network(
        fotoMenu,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: _getCategoryGradient('default'),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
      );
    }

    // Jika foto adalah base64 (string panjang)
    if (fotoMenu.length > 100) {
      try {
        // Handle base64 dengan atau tanpa prefix
        final base64String = fotoMenu.contains(',')
            ? fotoMenu.split(',').last
            : fotoMenu;

        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error decoding base64 image: $error');
            return Container(
              decoration: BoxDecoration(
                gradient: _getCategoryGradient('default'),
              ),
              child: const Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            );
          },
        );
      } catch (e) {
        print('Error displaying base64 image: $e');
        return Container(
          decoration: BoxDecoration(gradient: _getCategoryGradient('default')),
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    // Default jika tidak cocok dengan format apapun
    return Container(
      decoration: BoxDecoration(gradient: _getCategoryGradient('default')),
      child: const Center(
        child: Icon(Icons.restaurant_rounded, size: 40, color: Colors.white),
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
            // Modern Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats in a subtle pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 12,
                                ),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: AppColors.primary,
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
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
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
                                _selectedCategory = value == 'all'
                                    ? null
                                    : value;
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
                                          color: AppColors.primary.withOpacity(
                                            0.3,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Semua',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
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
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          _selectedCategory!,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getCategoryColor(
                            _selectedCategory!,
                          ).withOpacity(0.3),
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

            // Menu List
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        backgroundColor: AppColors.primary.withOpacity(
                          0.1,
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Text(
                          _searchQuery.isEmpty &&
                              _selectedCategory == null
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
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _filteredMenuList.length,
                        itemBuilder: (context, index) {
                          final menu = _filteredMenuList[index];
                          return _buildMenuCard(menu);
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border.withOpacity(0.3)),
          ),
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
            backgroundColor: AppColors.primary,
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
              const Icon(Icons.add_rounded, size: 24),
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
    final categoryColor = _getCategoryColor(category);
    final categoryGradient = _getCategoryGradient(category);
    final fotoMenu = menu['foto_menu']?.toString();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetailMenu(menu),
        child: SizedBox(
          width: double.infinity,
          height: 270,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Container
                Container(
                  height: 130,
                  decoration: BoxDecoration(gradient: categoryGradient),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image Background - GUNAKAN HELPER METHOD
                      _buildMenuImage(fotoMenu),

                      // Category Badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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

                // Content Container
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          namaMenu,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kode:  $idMenu',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
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
    return 'Rp${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

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
        return AppColors.primary;
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
