import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodlyfridge/screens/vendor_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// Import constants
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

import 'login_page.dart';
import 'pengaturan.dart';
import 'bahan_baku_page.dart';
import 'kedai_page.dart';
import 'menu_page.dart';
import 'staff_page.dart';
import 'waste_food_page.dart';
import 'stok_masuk_page.dart';
import 'kasir_page.dart';
import '../helpers/kedai_service.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String email;
  final String userId;
  final String? role; // 'admin', 'kasir', 'inventory'

  const HomePage({
    super.key,
    required this.username,
    required this.email,
    required this.userId,
    this.role,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = -1;

  String _storeName = "Kedai";
  bool _hasKedai = false;
  bool _isCheckingKedai = true;
  bool _dialogShown = false;

  final TextEditingController _namaKedaiPopupController =
      TextEditingController();
  final KedaiService _kedaiService = KedaiService();

  // Get filtered menu items based on role
  List<Map<String, dynamic>> get _filteredMenuItems {
    final role = widget.role?.toLowerCase() ?? 'admin';

    if (role == 'kasir') {
      // Kasir can only access: Menu, Kasir
      return _menuItems.where((item) {
        final route = item['route'];
        return route == -1 || route == 0 || route == 9; // Beranda, Menu, Kasir
      }).toList();
    } else if (role == 'inventory') {
      // Inventory can access: Bahan Baku, Stok Masuk, Sampah Bahan Baku
      return _menuItems.where((item) {
        final route = item['route'];
        return route == -1 ||
            route == 1 ||
            route == 2 ||
            route == 5; // Beranda, Bahan Baku, Stok Masuk, Sampah Bahan Baku
      }).toList();
    }

    // admin has full access
    return _menuItems;
  }

  List<Map<String, dynamic>> get _filteredDashboardMenuItems {
    final role = widget.role?.toLowerCase() ?? 'admin';

    if (role == 'kasir') {
      // Kasir dashboard: Menu, Kasir
      return _dashboardMenuItems.where((item) {
        final route = item['route'];
        return route == 0 || route == 9; // Menu, Kasir
      }).toList();
    } else if (role == 'inventory') {
      // Inventory dashboard: Stok Masuk, Bahan Baku, Sampah Bahan Baku
      return _dashboardMenuItems.where((item) {
        final route = item['route'];
        return route == 1 || route == 2 || route == 5; // Bahan Baku, Stok Masuk, Sampah Bahan Baku
      }).toList();
    }

    // admin has full access
    return _dashboardMenuItems;
  }

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_outlined, 'label': 'Beranda', 'route': -1},
    {'icon': Icons.restaurant_menu_outlined, 'label': 'Menu', 'route': 0},
    {'icon': Icons.upload_outlined, 'label': 'Stok Keluar', 'route': 3},
    {'icon': Icons.download_outlined, 'label': 'Stok Masuk', 'route': 2},
    {'icon': Icons.shopping_basket_outlined, 'label': 'Bahan Baku', 'route': 1},
    {'icon': Icons.delete_outline, 'label': 'Sampah Bahan Baku', 'route': 5},
    {'icon': Icons.people_outline, 'label': 'Staff', 'route': 7},
    {'icon': Icons.business_outlined, 'label': 'Vendor', 'route': 4},
    {'icon': Icons.history_outlined, 'label': 'Riwayat', 'route': 8},
    {'icon': Icons.point_of_sale_outlined, 'label': 'Kasir', 'route': 9},
    {'icon': Icons.video_library_outlined, 'label': 'Tutorial', 'route': 11},
    {'icon': Icons.analytics_outlined, 'label': 'Laporan', 'route': 6},
    {'icon': Icons.settings_outlined, 'label': 'Pengaturan', 'route': 10},
  ];

  final List<Map<String, dynamic>> _dashboardMenuItems = [
    {
      'icon': Icons.download_for_offline_outlined,
      'label': 'Stok Masuk',
      'route': 2,
      'color': AppColors.stockIn,
      'gradient': LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'icon': Icons.upload_outlined,
      'label': 'Stok Keluar',
      'route': 3,
      'color': AppColors.stockOut,
      'gradient': LinearGradient(
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'icon': Icons.shopping_basket,
      'label': 'Bahan Baku',
      'route': 1,
      'color': AppColors.accent,
      'gradient': LinearGradient(
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'icon': Icons.delete_forever_outlined,
      'label': 'Sampah Bahan Baku',
      'route': 5,
      'color': AppColors.danger,
      'gradient': LinearGradient(
        colors: [Color(0xFFf83600), Color(0xFFf9d423)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'icon': Icons.restaurant_menu,
      'label': 'Menu',
      'route': 0,
      'color': AppColors.menu,
      'gradient': LinearGradient(
        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'icon': Icons.analytics,
      'label': 'Laporan',
      'route': 6,
      'color': AppColors.report,
      'gradient': LinearGradient(
        colors: [Color(0xFFfa709a), Color(0xFFfee140)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'icon': Icons.people_alt,
      'label': 'Staff',
      'route': 7,
      'color': AppColors.staff,
      'gradient': LinearGradient(
        colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'icon': Icons.business,
      'label': 'Vendor',
      'route': 4,
      'color': AppColors.vendor,
      'gradient': LinearGradient(
        colors: [Color(0xFFcd9cf2), Color(0xFFf6f3ff)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'icon': Icons.history,
      'label': 'Riwayat',
      'route': 8,
      'color': AppColors.history,
      'gradient': LinearGradient(
        colors: [Color(0xFF89f7fe), Color(0xFF66a6ff)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'icon': Icons.point_of_sale,
      'label': 'Kasir',
      'route': 9,
      'color': AppColors.cashier,
      'gradient': LinearGradient(
        colors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'icon': Icons.settings,
      'label': 'Pengaturan',
      'route': 10,
      'color': AppColors.settings,
      'gradient': LinearGradient(
        colors: [Color(0xFFa3bded), Color(0xFF6991c7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'icon': Icons.video_library,
      'label': 'Tutorial',
      'route': 11,
      'color': AppColors.tutorial,
      'gradient': LinearGradient(
        colors: [Color(0xFFfad0c4), Color(0xFFffd1ff)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
  ];

  void _onMenuTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  void _onDashboardMenuTapped(int route) {
    setState(() {
      _selectedIndex = route;
    });
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFff6b6b), Color(0xFFff8e8e)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Keluar Akun',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Apakah Anda yakin ingin keluar dari Foodify?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: AppColors.border, width: 1.5),
                        ),
                        child: Text(
                          'Batal',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Keluar',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(  
      child: Column(
        children: [
          // Header Section dengan glassmorphism
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF764ba2).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar dengan user info
                SizedBox(height: 8), // <-- Tambah spacer kecil
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.username,
                          style: AppTextStyles.displaySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 28,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Store info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kedai Anda',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _storeName,
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Cards Section
          Transform.translate(
            offset: Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Kadaluarsa',
                      value: '0',
                      unit: 'Item',
                      icon: Icons.warning_amber_rounded,
                      gradient: LinearGradient(
                        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Hampir Habis',
                      value: '0',
                      unit: 'Item',
                      icon: Icons.inventory_2_rounded,
                      gradient: LinearGradient(
                        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dashboard Menu Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dashboard Menu',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667eea).withOpacity(0.1), Color(0xFF764ba2).withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xFF667eea).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.widgets_rounded,
                            size: 16,
                            color: Color(0xFF667eea),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_filteredDashboardMenuItems.length} Fitur',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Color(0xFF667eea),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Akses cepat ke semua fitur Foodify',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Grid Menu
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _filteredDashboardMenuItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredDashboardMenuItems[index];
                    return _buildDashboardMenuItem(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
                      gradient: item['gradient'] as LinearGradient,
                      color: item['color'] as Color,
                      onTap: () => _onDashboardMenuTapped(item['route'] as int),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom spacing
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unit,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.displaySmall.copyWith(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.border.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.last.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label.replaceAll('\n', ' '),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonContent(String title) {
    return Container(
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF764ba2).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.construction_rounded,
              size: 70,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Fitur ini sedang dalam pengembangan dan akan segera hadir',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedIndex = -1;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'Kembali ke Beranda',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedContent() {
    switch (_selectedIndex) {
      case 0:
        return const MenuPage();
      case 1:
        return const BahanBakuPage();
      case 2:
        return const StokMasukPage();
      case 3:
        return _buildComingSoonContent('Stok Keluar');
      case 4:
        return const VendorPage();
      case 5:
        return WasteFoodPage(userId: widget.userId, userName: widget.username);
      case 6:
        return _buildComingSoonContent('Laporan');
      case 7:
        return StaffPage(userId: widget.userId);
      case 8:
        return _buildComingSoonContent('Riwayat');
      case 9:
        return KasirPage();
      case 10:
        return PengaturanPage(userId: widget.userId);
      case 11:
        return _buildComingSoonContent('Tutorial');
      default:
        return _buildHomeContent();
    }
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Menu';
      case 1:
        return 'Bahan Baku';
      case 2:
        return 'Stok Masuk';
      case 3:
        return 'Stok Keluar';
      case 4:
        return 'Vendor';
      case 5:
        return 'Sampah Bahan Baku';
      case 6:
        return 'Laporan';
      case 7:
        return 'Staff';
      case 8:
        return 'Riwayat';
      case 9:
        return 'Kasir';
      case 10:
        return 'Pengaturan';
      case 11:
        return 'Tutorial';
      default:
        return _storeName;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeHomePage();
  }

  Future<void> _initializeHomePage() async {
    if (kDebugMode) {
      print('========== INITIALIZING HOME PAGE ==========');
      print('User ID: ${widget.userId}');
    }

    setState(() {
      _isCheckingKedai = true;
    });

    await Future.delayed(const Duration(milliseconds: 200));

    await _loadStoreName();

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _isCheckingKedai = false;
      });

      await Future.delayed(const Duration(milliseconds: 100));

      final role = widget.role?.toLowerCase() ?? 'admin';
      if (mounted && !_dialogShown && role == 'admin') {
        _checkAndShowKedaiDialog();
      }
    }
  }

  Future<void> _loadStoreName() async {
    final bool shouldLog = kDebugMode && !kIsWeb;

    if (shouldLog) {
      print('========== HOME PAGE: LOADING STORE NAME ==========');
      print('User ID: ${widget.userId}');
    }

    try {
      final kedai = await _kedaiService.getKedaiByUserId(widget.userId);

      if (kedai != null) {
        if (shouldLog) {
          print('Kedai loaded: ${kedai.nama_kedai}');
        }

        if (mounted) {
          setState(() {
            _storeName = kedai.nama_kedai;
            _hasKedai = true;
          });
        }

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('nama_kedai_${widget.userId}', kedai.nama_kedai);
        await prefs.setString('alamat_kedai_${widget.userId}', kedai.alamat_kedai);
        await prefs.setString('nomor_telepon_${widget.userId}', kedai.nomor_telepon);
        await prefs.setString('catatan_struk_${widget.userId}', kedai.catatan_struk);
        await prefs.setString('logo_kedai_${widget.userId}', kedai.logo_kedai);
        await prefs.setBool('has_kedai_${widget.userId}', true);
        await prefs.setString('kedai_id_${widget.userId}', kedai.id);

        if (shouldLog) {
          print('Store data synced to SharedPreferences');
        }
      } else {
        if (shouldLog) {
          print('No kedai from service, checking SharedPreferences...');
        }

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? savedStoreName = prefs.getString('nama_kedai_${widget.userId}');
        final bool? hasKedai = prefs.getBool('has_kedai_${widget.userId}');

        if (savedStoreName != null && savedStoreName.isNotEmpty && hasKedai == true) {
          if (mounted) {
            setState(() {
              _storeName = savedStoreName;
              _hasKedai = true;
            });
          }

          if (shouldLog) {
            print('Loaded from SharedPreferences cache: $savedStoreName');
          }
        } else {
          if (mounted) {
            setState(() {
              _hasKedai = false;
            });
          }

          if (shouldLog) {
            print('User does not have kedai data');
          }
        }
      }
    } catch (e) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedStoreName = prefs.getString('nama_kedai_${widget.userId}');
      final bool? hasKedai = prefs.getBool('has_kedai_${widget.userId}');

      if (savedStoreName != null && savedStoreName.isNotEmpty && hasKedai == true) {
        if (mounted) {
          setState(() {
            _storeName = savedStoreName;
            _hasKedai = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasKedai = false;
          });
        }
      }
    }
  }

  void _checkAndShowKedaiDialog() {
    if (kDebugMode) {
      print('========== CHECK AND SHOW KEDAI DIALOG ==========');
      print('Has Kedai: $_hasKedai');
      print('Dialog Shown: $_dialogShown');
    }

    if (!_hasKedai && !_dialogShown && mounted) {
      if (kDebugMode) {
        print('User does NOT have kedai - showing setup dialog');
      }
      _dialogShown = true;

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showSetupKedaiDialog();
        }
      });
    } else {
      if (kDebugMode) {
        if (_hasKedai) {
          print('User already has kedai - showing dashboard directly');
        } else if (_dialogShown) {
          print('Dialog already shown - skipping');
        }
      }
    }
  }

  void _showSetupKedaiDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF764ba2).withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Atur Kedai Anda',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mari atur kedai Anda terlebih dahulu untuk memulai menggunakan Foodify',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();

                        if (kDebugMode) {
                          print('User clicked setup - navigating to KedaiPage');
                        }

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KedaiPage(userId: widget.userId),
                          ),
                        );

                        if (result == true) {
                          if (kDebugMode) {
                            print('Kedai setup completed successfully - reloading data');
                          }
                          await _loadStoreName();
                          if (mounted) {
                            setState(() {
                              _hasKedai = true;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Mulai Atur Kedai',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Nanti Saja',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingKedai) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  color: Color(0xFF667eea),
                  backgroundColor: Color(0xFF667eea).withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Memuat aplikasi...',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Foodify',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Color(0xFF667eea),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: _selectedIndex == -1
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              leading: Builder(
                builder: (context) => Container(
                  margin: EdgeInsets.only(left: 8),
                  child: IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(
                'Beranda',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
              actions: [
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: () {
                      // Notification action
                    },
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : AppBar(
              backgroundColor: AppColors.surface,
              elevation: 2,
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
                onPressed: () {
                  setState(() {
                    _selectedIndex = -1;
                  });
                },
              ),
              title: Text(
                _getPageTitle(),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.menu_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
      drawer: _buildSideDrawer(),
      body: _selectedIndex == -1 
          ? SafeArea(  // <-- TAMBAHKAN SafeArea HANYA UNTUK BERANDA
              bottom: false,
              child: _buildHomeContent(),
            )
          : _getSelectedContent(), // <-- Halaman lain tanpa SafeArea  
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // Drawer Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 70, 28, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Avatar
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.username,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.role != null && widget.role!.isNotEmpty
                          ? widget.role!.toUpperCase()
                          : 'ADMIN',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drawer Menu Items
          Expanded(
            child: Container(
              color: AppColors.background,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  const SizedBox(height: 8),
                  ...List.generate(_filteredMenuItems.length, (index) {
                    final item = _filteredMenuItems[index];
                    final isSelected = _selectedIndex == item['route'];
                    
                    // State untuk track hover
                    bool isHovered = false;
                    
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => setState(() => isHovered = true),
                          onExit: (_) => setState(() => isHovered = false),
                          child: GestureDetector(
                            onTap: () => _onMenuTapped(item['route'] as int),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: Container( // <-- PAKAI Container, BUKAN AnimatedContainer
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.1)
                                      : (isHovered ? AppColors.primary.withOpacity(0.05) : Colors.transparent),
                                  borderRadius: BorderRadius.circular(16),
                                  // PAKAI BORDER dengan width KONSTAN (1) agar tidak bergerak
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.3)
                                        : (isHovered ? AppColors.primary.withOpacity(0.1) : Colors.transparent),
                                    width: 1, // <-- WIDTH SELALU 1, TIDAK BERUBAH
                                  ),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : (isHovered
                                              ? LinearGradient(
                                                  colors: [
                                                    Color(0xFF667eea).withOpacity(0.2),
                                                    Color(0xFF764ba2).withOpacity(0.1)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : LinearGradient(
                                                  colors: [
                                                    AppColors.textSecondary.withOpacity(0.1),
                                                    AppColors.textSecondary.withOpacity(0.05)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Color(0xFF764ba2).withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: Offset(0, 4),
                                              ),
                                            ]
                                          : (isHovered
                                              ? [
                                                  BoxShadow(
                                                    color: Color(0xFF667eea).withOpacity(0.1),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ]
                                              : null),
                                    ),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      size: 22,
                                      color: isSelected
                                          ? Colors.white
                                          : (isHovered ? Color(0xFF667eea) : AppColors.textSecondary),
                                    ),
                                  ),
                                  title: Text(
                                    item['label'] as String,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isHovered ? Color(0xFF667eea) : AppColors.textPrimary),
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : (isHovered ? FontWeight.w600 : FontWeight.w500),
                                    ),
                                  ),
                                  trailing: isSelected || isHovered
                                      ? Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF667eea).withOpacity(isSelected ? 0.1 : 0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            color: Color(0xFF667eea),
                                            size: 20,
                                          ),
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Logout Button
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFff6b6b).withOpacity(0.1), Color(0xFFff8e8e).withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFff6b6b).withOpacity(0.2)),
              ),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFff6b6b), Color(0xFFff8e8e)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  'Keluar',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: _logout,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}