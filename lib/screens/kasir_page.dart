// screens/kasir_page.dart - VERSI MODERN & PROFESSIONAL
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config.dart';
import '../restapi.dart';
import '../model/menu_model.dart';
import '../model/stok_keluar.dart';
import '../model/bahan_baku_model.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({Key? key}) : super(key: key);

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  final DataService _dataService = DataService();
  
  List<MenuModel> _menuList = [];
  bool _isLoading = false;
  
  // Data pesanan
  final List<_CartItem> _cartItems = [];
  
  // Untuk operasi harga
  double _totalHarga = 0.0;
  String _inputHarga = '';
  String _searchQuery = '';
  
  // Kategori filter
  String _selectedCategory = 'Semua';
  List<String> _categories = ['Semua'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final menuResponse = await _dataService.selectAll(token, project, 'menu', appid);
      
      if (menuResponse.isNotEmpty && menuResponse != '[]' && menuResponse != 'null') {
        final decoded = json.decode(menuResponse);
        List<dynamic> menuDataList;
        
        if (decoded is Map && decoded.containsKey('data')) {
          menuDataList = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          menuDataList = decoded;
        } else {
          menuDataList = [];
        }
        
        _menuList = menuDataList
            .map((j) => MenuModel.fromJson(j))
            .toList();
            
        // Extract categories
        final categories = _menuList.map((m) => m.kategori).toSet().toList();
        _categories = ['Semua'] + categories;
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      Fluttertoast.showToast(msg: "Gagal memuat data", backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    final existingIndex = _cartItems.indexWhere((item) => item.menu.id == menu.id);
    
    if (existingIndex != -1) {
      setState(() {
        _cartItems[existingIndex] = _CartItem(
          menu: menu,
          quantity: _cartItems[existingIndex].quantity + 1,
        );
      });
    } else {
      setState(() {
        _cartItems.add(_CartItem(
          menu: menu,
          quantity: 1,
        ));
      });
    }
    
    _calculateTotal();
    _showToast("✓ ${menu.nama_menu} ditambahkan", isSuccess: true);
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
    
    setState(() {
      _cartItems[index] = _CartItem(
        menu: _cartItems[index].menu,
        quantity: newQuantity,
      );
    });
    
    _calculateTotal();
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in _cartItems) {
      final harga = double.tryParse(item.menu.harga) ?? 0.0;
      total += harga * item.quantity;
    }
    
    // Tambahkan input harga manual jika ada
    if (_inputHarga.isNotEmpty) {
      final manualHarga = double.tryParse(_inputHarga) ?? 0.0;
      total += manualHarga;
    }
    
    setState(() {
      _totalHarga = total;
    });
  }

  // Fungsi untuk operasi harga
  void _handleNumpadInput(String value) {
    if (value == 'C') {
      setState(() {
        _inputHarga = '';
      });
      _calculateTotal();
    } else if (value == '⌫') {
      if (_inputHarga.isNotEmpty) {
        setState(() {
          _inputHarga = _inputHarga.substring(0, _inputHarga.length - 1);
        });
      }
    } else if (value == '+') {
      if (_inputHarga.isNotEmpty) {
        final harga = double.tryParse(_inputHarga) ?? 0.0;
        setState(() {
          _totalHarga += harga;
          _inputHarga = '';
        });
        _showToast("+ Rp ${_formatNumber(harga)}", isSuccess: true);
      }
    } else if (value == '=') {
      if (_inputHarga.isNotEmpty) {
        final harga = double.tryParse(_inputHarga) ?? 0.0;
        setState(() {
          _totalHarga = harga;
          _inputHarga = '';
        });
        _showToast("Total di-set ke Rp ${_formatNumber(harga)}", isSuccess: true);
      }
    } else {
      setState(() {
        _inputHarga += value;
      });
    }
  }

  Widget _buildNumpad() {
    final List<List<String>> numpadLayout = [
      ['1', '2', '3', 'C'],
      ['4', '5', '6', '⌫'],
      ['7', '8', '9', '+'],
      ['00', '0', '000', '='],
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Display input
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Input Harga',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Rp ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _inputHarga.isEmpty ? '0' : _formatNumber(double.tryParse(_inputHarga) ?? 0),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Numpad grid
          Expanded(
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
                final row = index ~/ 4;
                final col = index % 4;
                final text = numpadLayout[row][col];
                
                return _buildNumpadButton(text);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(String text) {
    bool isNumber = RegExp(r'^[0-9]+$').hasMatch(text);
    bool isSpecial = ['C', '⌫', '+', '='].contains(text);
    
    Color bgColor = isNumber ? Colors.white : Color(0xFFE3F2FD);
    Color textColor = isNumber ? Colors.black : Color(0xFF1976D2);
    
    if (text == 'C') {
      bgColor = Color(0xFFFFEBEE);
      textColor = Color(0xFFD32F2F);
    } else if (text == '⌫') {
      bgColor = Color(0xFFFFF3E0);
      textColor = Color(0xFFF57C00);
    }
    
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: bgColor,
      elevation: 2,
      child: InkWell(
        onTap: () => _handleNumpadInput(text),
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(MenuModel menu) {
    final harga = double.tryParse(menu.harga) ?? 0.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _addToCart(menu),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kode menu
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  menu.kode_menu,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              SizedBox(height: 8),
              
              // Nama menu
              Text(
                menu.nama_menu,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              Spacer(),
              
              // Harga dan tombol
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Rp ${_formatNumber(harga)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(_CartItem item, int index) {
    final harga = double.tryParse(item.menu.harga) ?? 0.0;
    final subtotal = harga * item.quantity;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
        child: Row(
          children: [
            // Quantity indicator
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Kode: ${item.menu.kode_menu}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Subtotal
            Text(
              'Rp ${_formatNumber(subtotal)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4CAF50),
              ),
            ),
            
            SizedBox(width: 12),
            
            // Quantity controls
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _updateQuantity(index, item.quantity - 1),
                    icon: Icon(Icons.remove, size: 16),
                    color: Colors.grey[700],
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  Container(
                    width: 24,
                    child: Center(
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateQuantity(index, item.quantity + 1),
                    icon: Icon(Icons.add, size: 16),
                    color: Colors.grey[700],
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 8),
            
            // Delete button
            IconButton(
              onPressed: () => _removeFromCart(index),
              icon: Icon(Icons.delete_outline, size: 20),
              color: Colors.red[400],
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String message, {bool isSuccess = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isSuccess ? Color(0xFF4CAF50) : Colors.red,
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF2196F3)),
              ),
            )
          : Row(
              children: [
                // Left Panel - Menu
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Color(0xFFF8F9FA),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                  prefixIcon: Icon(Icons.search, color: Color(0xFF1976D2)),
                                  filled: true,
                                  fillColor: Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                ),
                              ),
                              
                              SizedBox(height: 12),
                              
                              // Categories
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _categories.map((category) {
                                    final isSelected = _selectedCategory == category;
                                    return Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(category),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedCategory = selected ? category : 'Semua';
                                          });
                                        },
                                        backgroundColor: Colors.white,
                                        selectedColor: Color(0xFF2196F3),
                                        labelStyle: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          side: BorderSide(
                                            color: isSelected ? Color(0xFF2196F3) : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
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
                                childAspectRatio: 0.85,
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
                  color: Colors.grey[200],
                ),
                
                // Right Panel - Cart & Numpad
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Cart Header
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                color: Color(0xFF2196F3),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Keranjang Pesanan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_cartItems.length} item',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Cart Items
                        Expanded(
                          child: _cartItems.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 80,
                                        color: Colors.grey[300],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Keranjang Kosong',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tambahkan item dari menu',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    children: _cartItems.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      return _buildCartItem(item, index);
                                    }).toList(),
                                  ),
                                ),
                        ),
                        
                        // Total Summary
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.grey[200]!),
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Item:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${_cartItems.length}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Divider(color: Colors.grey[300]),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Harga:',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatNumber(_totalHarga)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Numpad Section
                        Container(
                          height: MediaQuery.of(context).size.height * 0.35,
                          child: _buildNumpad(),
                        ),
                        
                        // Action Buttons
                        Container(
                          padding: EdgeInsets.all(16),
                          color: Colors.white,
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _cartItems.isEmpty ? null : () {
                                    setState(() {
                                      _cartItems.clear();
                                      _totalHarga = 0.0;
                                      _inputHarga = '';
                                    });
                                    _showToast("Keranjang dibersihkan");
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Color(0xFFD32F2F),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Color(0xFFD32F2F)),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete_outline, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Bersihkan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _cartItems.isEmpty ? null : () {
                                    // TODO: Implement process order
                                    _showToast("Pesanan berhasil diproses!", isSuccess: true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.payment, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Proses Pembayaran',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Helper class untuk cart item
class _CartItem {
  final MenuModel menu;
  int quantity;

  _CartItem({
    required this.menu,
    required this.quantity,
  });
}