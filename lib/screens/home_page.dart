import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodlyfridge/screens/vendor_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'login_page.dart';
import 'pengaturan.dart';
import 'bahan_baku_page.dart';
import 'kedai_page.dart';
import 'menu_page.dart';
import 'staff_page.dart';
import '../helpers/kedai_service.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String email;
  final String userId;

  const HomePage({
    super.key,
    required this.username,
    required this.email,
    required this.userId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = -1;

  final Color _primaryColor = const Color(0xFFB53929);
  final Color _primaryLightColor = const Color(0xFFD14633);
  final Color _menuColor = const Color(0xFF7A9B3B);

  String _storeName = "Kedai";
  bool _hasKedai = false;
  bool _isCheckingKedai = true;
  bool _dialogShown = false;

  final TextEditingController _namaKedaiPopupController = TextEditingController();
  final KedaiService _kedaiService = KedaiService();

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home_outlined, 'label': 'Beranda', 'route':  -1},
    {'icon': Icons.restaurant_menu, 'label': 'Menu', 'route': 0},
    {'icon': Icons.arrow_upward, 'label': 'Stok Keluar', 'route': 3},
    {'icon': Icons. arrow_downward, 'label':  'Stok Masuk', 'route': 2},
    {'icon': Icons. eco_outlined, 'label': 'Bahan Baku', 'route': 1},
    {'icon': Icons.no_food_outlined, 'label': 'Sampah Bahan Baku', 'route': 5},
    {'icon': Icons. people_alt_outlined, 'label': 'Staff', 'route': 7},
    {'icon': Icons. groups_outlined, 'label': 'Vendor', 'route': 4},
    {'icon': Icons.history, 'label': 'Riwayat', 'route':  8},
    {'icon': Icons.person_outline, 'label': 'Kasir', 'route': 9},
    {'icon': Icons.play_circle_outline, 'label': 'Tutorial', 'route': 11},
    {'icon': Icons.bar_chart, 'label': 'Laporan', 'route': 6},
    {'icon': Icons.settings_outlined, 'label': 'Pengaturan', 'route':  10},
  ];

  final List<Map<String, dynamic>> _dashboardMenuItems = [
    {'icon':  Icons.arrow_downward_rounded, 'label': 'Stok Masuk', 'route': 2},
    {'icon': Icons.arrow_upward_rounded, 'label': 'Stok Keluar', 'route': 3},
    {'icon': Icons.eco_rounded, 'label': 'Bahan Baku', 'route': 1},
    {'icon': Icons.no_food_rounded, 'label': 'Sampah Bahan\nBaku', 'route':  5},
    {'icon':  Icons.restaurant_menu_rounded, 'label': 'Menu', 'route': 0},
    {'icon': Icons. bar_chart_rounded, 'label': 'Laporan', 'route': 6},
    {'icon': Icons.people_alt_rounded, 'label': 'Staff', 'route': 7},
    {'icon': Icons.groups_rounded, 'label': 'Vendor', 'route': 4},
    {'icon': Icons.history_rounded, 'label': 'Riwayat', 'route': 8},
    {'icon': Icons.person_rounded, 'label': 'Kasir', 'route': 9},
    {'icon': Icons.settings_rounded, 'label': 'Pengaturan', 'route': 10},
    {'icon': Icons.play_circle_outline_rounded, 'label': 'Tutorial', 'route': 11},
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

  // Method untuk clear cache user saat logout
  // Future<void> _clearUserCache() async {
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('nama_kedai_${widget.userId}');
  //   await prefs.remove('has_kedai_${widget.userId}');
  //
  //   if (kDebugMode) {
  //     print('User cache cleared for user:  ${widget.userId}');
  //   }
  // }

  void _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar? '),
          actions: [
            TextButton(
              onPressed:  () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                // Clear user cache (optional, data tetap ada di database)
                // await _clearUserCache();

                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
              child: const Text(
                'Keluar',
                style: TextStyle(color:  Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors. white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Hari Ini',
                  style: GoogleFonts.poppins(
                    fontSize:  18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7A9B3B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:  CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kadaluarsa',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '0',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight:  FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'item',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors. grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors. grey[300],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hampir Habis',
                            style: GoogleFonts.poppins(
                              fontSize:  14,
                              color:  Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height:  8),
                          Row(
                            children: [
                              Text(
                                '0',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'item',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Grid Menu
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:  const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing:  16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
            ),
            itemCount: _dashboardMenuItems.length,
            itemBuilder: (context, index) {
              final item = _dashboardMenuItems[index];
              return _buildDashboardMenuItem(
                icon: item['icon'] as IconData,
                label:  item['label'] as String,
                onTap: () => _onDashboardMenuTapped(item['route'] as int),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:  Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child:  Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _menuColor. withValues(alpha: 0.1),
                    borderRadius:  BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: _menuColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonContent(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height:  12),
          Text(
            'Fitur ini sedang dalam pengembangan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
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
        return _buildComingSoonContent('Stok Masuk');
      case 3:
        return _buildComingSoonContent('Stok Keluar');
      case 4:
        return const VendorPage();
      case 5:
        return _buildComingSoonContent('Sampah Bahan Baku');
      case 6:
        return _buildComingSoonContent('Laporan');
      case 7:
        return StaffPage(userId: widget.userId);
      case 8:
        return _buildComingSoonContent('Riwayat');
      case 9:
        return _buildComingSoonContent('Kasir');
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

  //PERBAIKAN: Method untuk initialize home page dengan delay
  Future<void> _initializeHomePage() async {
    if (kDebugMode) {
      print('========== INITIALIZING HOME PAGE ==========');
      print('User ID: ${widget. userId}');
    }

    setState(() {
      _isCheckingKedai = true;
    });

    // PENTING: Tunggu sedikit untuk memastikan widget sudah mounted
    await Future.delayed(const Duration(milliseconds: 200));

    // Load nama kedai dan cek status
    await _loadStoreName();

    //PENTING: Tunggu sedikit sebelum hide loading
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _isCheckingKedai = false;
      });

      //PENTING: Tunggu UI selesai render sebelum cek dialog
      await Future.delayed(const Duration(milliseconds: 100));

      // Setelah selesai check, baru tampilkan popup jika diperlukan
      if (mounted && !_dialogShown) {
        _checkAndShowKedaiDialog();
      }
    }
  }

  // PERBAIKAN: Method untuk load nama kedai dengan retry mechanism yang lebih robust
  Future<void> _loadStoreName() async {
    // ✅ Suppress log untuk web platform
    final bool shouldLog = kDebugMode && !kIsWeb;

    if (shouldLog) {
      print('========== HOME PAGE: LOADING STORE NAME ==========');
      print('User ID: ${widget.userId}');
    }

    try {
      // ✅ PERBAIKAN: Panggil sekali saja, kedai_service sudah handle cache & retry
      final kedai = await _kedaiService.getKedaiByUserId(widget.userId);

      if (kedai != null) {
        if (shouldLog) {
          print('✅ Kedai loaded: ${kedai.nama_kedai}');
        }

        if (mounted) {
          setState(() {
            _storeName = kedai.nama_kedai;
            _hasKedai = true;
          });
        }

        // Sinkronisasi ke SharedPreferences untuk backup
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('nama_kedai_${widget.userId}', kedai.nama_kedai);
        await prefs.setString('alamat_kedai_${widget.userId}', kedai.alamat_kedai);
        await prefs.setString('nomor_telepon_${widget.userId}', kedai.nomor_telepon);
        await prefs.setString('catatan_struk_${widget.userId}', kedai.catatan_struk);
        await prefs.setString('logo_kedai_${widget.userId}', kedai.logo_kedai);
        await prefs.setBool('has_kedai_${widget.userId}', true);
        await prefs.setString('kedai_id_${widget.userId}', kedai.id);

        if (shouldLog) {
          print('✅ Store data synced to SharedPreferences');
        }
      } else {
        // Tidak ada kedai, cek cache SharedPreferences sebagai fallback
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
            print('✅ Loaded from SharedPreferences cache: $savedStoreName');
          }
        } else {
          // Tidak ada data sama sekali
          if (mounted) {
            setState(() {
              _hasKedai = false;
            });
          }

          if (shouldLog) {
            print('ℹ️ User does not have kedai data');
          }
        }
      }
    } catch (e) {
      // ✅ Suppress error log untuk web

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

  // PERBAIKAN: Method untuk cek dan tampilkan dialog setup kedai
  void _checkAndShowKedaiDialog() {
    if (kDebugMode) {
      print('========== CHECK AND SHOW KEDAI DIALOG ==========');
      print('Has Kedai: $_hasKedai');
      print('Dialog Shown: $_dialogShown');
    }

    // PENTING:  Hanya tampilkan popup jika user TIDAK punya kedai DAN dialog belum pernah ditampilkan
    if (!_hasKedai && !_dialogShown && mounted) {
      if (kDebugMode) {
        print('User does NOT have kedai - showing setup dialog');
      }
      _dialogShown = true;

      // Delay sedikit untuk memastikan UI sudah siap
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
          child:  Align(
            alignment: Alignment. bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors. white,
                  borderRadius:  BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child:  Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Atur nama kedaimu, sekarang',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width:  double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();

                          if (kDebugMode) {
                            print('User clicked Ayo!  - navigating to KedaiPage');
                          }

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:  (context) => KedaiPage(userId: widget.userId),
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
                        style: ElevatedButton. styleFrom(
                          backgroundColor:  _primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Ayo! ',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors. white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: _primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Memuat data...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors. grey[50],
      appBar: AppBar(
        backgroundColor:  _primaryColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon:  const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          _getPageTitle(),
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: const BoxDecoration(
                color:  Colors.white,
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color:  Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 30,
                            color: Colors. grey[600],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.email,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors. grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Admin',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _menuColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: ListView(
                  padding: EdgeInsets. zero,
                  children: [
                    const SizedBox(height: 8),
                    ... List.generate(_menuItems.length, (index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedIndex == item['route'];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading:  Icon(
                            item['icon'] as IconData,
                            color: _menuColor,
                            size: 24,
                          ),
                          title: Text(
                            item['label'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[900],
                            ),
                          ),
                          onTap: () => _onMenuTapped(item['route'] as int),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading:  Icon(
                        Icons.logout,
                        color: _primaryColor,
                        size: 24,
                      ),
                      title: Text(
                        'Keluar',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                      onTap: _logout,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _getSelectedContent(),
    );
  }
}
