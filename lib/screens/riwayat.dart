import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../model/stok_masuk.dart';
import '../model/waste_food.dart';

class RiwayatPage extends StatefulWidget {
  final String userId;
  final String userName;

  const RiwayatPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  bool _isLoading = false;
  List<TransactionHistory> _allTransactions = [];
  List<TransactionHistory> _filteredTransactions = [];
  String _selectedFilter = 'Semua';

  final List<String> _filterOptions = [
    'Semua',
    'Stok Masuk',
    'Stok Keluar',
    'Sampah',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllTransactions();
  }

  Future<void> _loadAllTransactions() async {
    setState(() => _isLoading = true);

    try {
      // Clear previous data
      _allTransactions.clear();

      print('Loading all transactions...');

      // Load all transaction types in parallel
      await Future.wait([
        _loadStokMasuk(),
        _loadStokKeluar(),
        _loadWasteFood(),
      ]);

      print(' Loaded ${_allTransactions.length} total transactions');
      print('   - Stok Masuk: ${_allTransactions.where((t) => t.type == TransactionType.stokMasuk).length}');
      print('   - Stok Keluar: ${_allTransactions.where((t) => t.type == TransactionType.stokKeluar).length}');
      print('   - Sampah: ${_allTransactions.where((t) => t.type == TransactionType.sampah).length}');

      // Sort by date (newest first)
      _allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _filteredTransactions = List.from(_allTransactions);
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, Map<String, String>>> _loadBahanBakuMap() async {
    Map<String, Map<String, String>> bahanBakuMap = {};

    try {
      final url = '$fileUri/select/';
      final body = {
        'token': token,
        'project': project,
        'collection': 'bahan_baku',
        'appid': appid,
      };

      print('🔍 Loading Bahan Baku Map...');
      print('   URL: $url');
      print('   Body: $body');

      final response = await http.post(
        Uri.parse(url),
        body: body,
      );

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data is List) {
          for (var item in data) {
            String id = item['_id']?.toString() ?? '';
            if (id.isNotEmpty) {
              bahanBakuMap[id] = {
                'nama': item['nama_bahan']?.toString() ?? 'Unknown',
                'unit': item['unit']?.toString() ?? 'gr',
              };
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error loading bahan baku map: $e');
    }

    return bahanBakuMap;
  }

  Future<void> _loadStokMasuk() async {
    try {
      print('📦 Loading Stok Masuk...');

      // First, load all bahan baku to create a map
      final bahanBakuMap = await _loadBahanBakuMap();
      print('   Found ${bahanBakuMap.length} bahan baku items');

      final url = '$fileUri/select/';
      final body = {
        'token': token,
        'project': project,
        'collection': 'stok_masuk',
        'appid': appid,
      };

      print('   URL: $url');
      print('   Body: $body');

      final response = await http.post(
        Uri.parse(url),
        body: body,
      );

      print('   Response status: ${response.statusCode}');
      print('   Response body length: ${response.body.length}');
      print('   Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        print('   Decoded data type: ${data.runtimeType}');

        if (data is List) {
          print('   Found ${data.length} stok masuk records');

          for (var item in data) {
            try {
              final stokMasuk = StokMasukModel.fromJson(item);

              // Parse tanggal
              DateTime timestamp;
              try {
                timestamp = DateTime.parse(stokMasuk.tanggal_masuk);
              } catch (e) {
                // Try alternative format
                try {
                  final parts = stokMasuk.tanggal_masuk.split('-');
                  if (parts.length == 3) {
                    timestamp = DateTime(
                      int.parse(parts[0]),
                      int.parse(parts[1]),
                      int.parse(parts[2]),
                    );
                  } else {
                    timestamp = DateTime.now();
                  }
                } catch (e2) {
                  timestamp = DateTime.now();
                }
              }

              // Get bahan baku name from map
              String bahanName = 'Unknown';
              String unit = 'gr';

              if (bahanBakuMap.containsKey(stokMasuk.kode_bahan)) {
                bahanName = bahanBakuMap[stokMasuk.kode_bahan]!['nama'] ?? 'Unknown';
                unit = bahanBakuMap[stokMasuk.kode_bahan]!['unit'] ?? 'gr';
              }

              _allTransactions.add(TransactionHistory(
                type: TransactionType.stokMasuk,
                timestamp: timestamp,
                itemName: bahanName,
                quantity: '+${stokMasuk.qty_pembelian}',
                unit: unit,
                performedBy: 'Inventaris (${widget.userName})',
                vendor: stokMasuk.nama_vendor,
                totalPrice: stokMasuk.total_harga,
              ));
            } catch (e) {
              print('Error parsing stok masuk item: $e');
            }
          }
          print('   ✅ Added ${_allTransactions.where((t) => t.type == TransactionType.stokMasuk).length} stok masuk transactions');
        }
      }
    } catch (e) {
      print('❌ Error loading stok masuk: $e');
    }
  }

  Future<void> _loadStokKeluar() async {
    try {
      print('🛒 Loading Stok Keluar...');

      final response = await http.post(
        Uri.parse('$fileUri/select/'),
        body: {
          'token': token,
          'project': project,
          'collection': 'stok_keluar',
          'appid': appid,
        },
      );

      print('   Response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data is List) {
          print('   Found ${data.length} stok keluar records');

          for (var item in data) {
            try {
              // Parse tanggal
              DateTime timestamp;
              try {
                timestamp = DateTime.parse(item['tanggal']);
              } catch (e) {
                // Try alternative format
                try {
                  final dateStr = item['tanggal']?.toString() ?? '';
                  // Format: "09/01/2026 22:16"
                  if (dateStr.contains('/')) {
                    final parts = dateStr.split(' ');
                    final dateParts = parts[0].split('/');
                    final timeParts = parts.length > 1 ? parts[1].split(':') : ['0', '0'];

                    timestamp = DateTime(
                      int.parse(dateParts[2]), // year
                      int.parse(dateParts[1]), // month
                      int.parse(dateParts[0]), // day
                      int.parse(timeParts[0]), // hour
                      int.parse(timeParts[1]), // minute
                    );
                  } else {
                    timestamp = DateTime.now();
                  }
                } catch (e2) {
                  timestamp = DateTime.now();
                }
              }

              // Parse menu to extract items
              String menuStr = item['menu']?.toString() ?? '';

              if (menuStr.isEmpty) {
                continue;
              }

              // Handle both newline and comma separated formats
              List<String> menuItems = menuStr.contains('\n')
                  ? menuStr.split('\n')
                  : menuStr.split(',');

              for (String menuItem in menuItems) {
                if (menuItem.trim().isEmpty) continue;

                // Parse menu item: "2x Nasi Goreng" or "2 x Nasi Goreng"
                String itemName = menuItem.trim();
                String qty = '1';

                // Try different patterns
                RegExp regex1 = RegExp(r'^(\d+)\s*x\s*(.+)$', caseSensitive: false);
                RegExp regex2 = RegExp(r'^(.+)\s*\((\d+)\)$');

                Match? match = regex1.firstMatch(itemName);
                if (match != null) {
                  qty = match.group(1) ?? '1';
                  itemName = match.group(2)?.trim() ?? itemName;
                } else {
                  match = regex2.firstMatch(itemName);
                  if (match != null) {
                    itemName = match.group(1)?.trim() ?? itemName;
                    qty = match.group(2) ?? '1';
                  }
                }

                _allTransactions.add(TransactionHistory(
                  type: TransactionType.stokKeluar,
                  timestamp: timestamp,
                  itemName: itemName,
                  quantity: '-$qty',
                  unit: 'pcs',
                  performedBy: 'Kasir (${widget.userName})',
                  invoice: item['invoice']?.toString() ?? '-',
                  customerName: item['nama_pemesanan']?.toString() ?? 'Customer',
                ));
              }
            } catch (e) {
              print('Error parsing stok keluar item: $e');
            }
          }
          print('   ✅ Added ${_allTransactions.where((t) => t.type == TransactionType.stokKeluar).length} stok keluar transactions');
        }
      }
    } catch (e) {
      print('❌ Error loading stok keluar: $e');
    }
  }

  Future<void> _loadWasteFood() async {
    try {
      print('🗑️ Loading Waste Food...');

      final response = await http.post(
        Uri.parse('$fileUri/select/'),
        body: {
          'token': token,
          'project': project,
          'collection': 'waste_food',
          'appid': appid,
        },
      );

      print('   Response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data is List) {
          print('   Found ${data.length} waste food records');

          for (var item in data) {
            try {
              final waste = WasteFoodModel.fromJson(item);

              // Parse tanggal
              DateTime timestamp;
              try {
                timestamp = DateTime.parse(waste.tanggal);
              } catch (e) {
                // Try alternative format
                try {
                  final dateStr = waste.tanggal;
                  // Format: "09/01/2026" or "2026-01-09"
                  if (dateStr.contains('/')) {
                    final parts = dateStr.split('/');
                    timestamp = DateTime(
                      int.parse(parts[2]), // year
                      int.parse(parts[1]), // month
                      int.parse(parts[0]), // day
                    );
                  } else if (dateStr.contains('-')) {
                    final parts = dateStr.split('-');
                    timestamp = DateTime(
                      int.parse(parts[0]), // year
                      int.parse(parts[1]), // month
                      int.parse(parts[2]), // day
                    );
                  } else {
                    timestamp = DateTime.now();
                  }
                } catch (e2) {
                  timestamp = DateTime.now();
                }
              }

              // Parse unit from jumlah_terbuang if it contains unit
              String qty = waste.jumlah_terbuang;
              String unit = 'gr';

              // Extract unit if present in quantity string
              final qtyMatch = RegExp(r'(\d+\.?\d*)\s*(\w+)?').firstMatch(qty);
              if (qtyMatch != null) {
                qty = qtyMatch.group(1) ?? qty;
                unit = qtyMatch.group(2) ?? 'gr';
              }

              _allTransactions.add(TransactionHistory(
                type: TransactionType.sampah,
                timestamp: timestamp,
                itemName: waste.nama_bahan,
                quantity: '-$qty',
                unit: unit,
                performedBy: 'Inventaris (${widget.userName})',
                jenisWaste: waste.jenis_waste,
                kerugian: waste.total_kerugian,
              ));
            } catch (e) {
              print('Error parsing waste food item: $e');
            }
          }
          print('   ✅ Added ${_allTransactions.where((t) => t.type == TransactionType.sampah).length} waste food transactions');
        }
      }
    } catch (e) {
      print('❌ Error loading waste food: $e');
    }
  }


  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;

      if (filter == 'Semua') {
        _filteredTransactions = List.from(_allTransactions);
      } else {
        TransactionType type;
        switch (filter) {
          case 'Stok Masuk':
            type = TransactionType.stokMasuk;
            break;
          case 'Stok Keluar':
            type = TransactionType.stokKeluar;
            break;
          case 'Sampah':
            type = TransactionType.sampah;
            break;
          default:
            type = TransactionType.stokMasuk;
        }

        _filteredTransactions = _allTransactions
            .where((t) => t.type == type)
            .toList();
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.stokMasuk:
        return const Color(0xFF7A9B3B); // Green
      case TransactionType.stokKeluar:
        return const Color(0xFFD4662A); // Orange
      case TransactionType.sampah:
        return const Color(0xFF8B4513); // Brown
    }
  }

  String _getTransactionTitle(TransactionType type) {
    switch (type) {
      case TransactionType.stokMasuk:
        return 'Stok Masuk';
      case TransactionType.stokKeluar:
        return 'Stok Keluar';
      case TransactionType.sampah:
        return 'Sampah';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) _applyFilter(filter);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF7A9B3B).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF7A9B3B),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF7A9B3B) : Colors.grey[700],
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF7A9B3B) : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      elevation: 0,
                      pressElevation: 0,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Transaction list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAllTransactions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _filteredTransactions[index];

                            // Show date divider
                            bool showDateDivider = false;
                            if (index == 0) {
                              showDateDivider = true;
                            } else {
                              final prevTransaction = _filteredTransactions[index - 1];
                              if (!_isSameDay(transaction.timestamp, prevTransaction.timestamp)) {
                                showDateDivider = true;
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDateDivider) ...[
                                  if (index > 0) const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                                    child: Text(
                                      _formatDate(transaction.timestamp),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                                _buildTransactionCard(transaction),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Riwayat transaksi akan muncul di sini',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionHistory transaction) {
    final color = _getTransactionColor(transaction.type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left colored indicator with time
            Container(
              width: 70,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  _formatTime(transaction.timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction type title
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getTransactionTitle(transaction.type),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Item name with quantity
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            transaction.itemName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${transaction.quantity} ${transaction.unit}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Performed by
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            transaction.performedBy,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Additional info based on type
                    if (transaction.type == TransactionType.stokMasuk && transaction.vendor != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Vendor: ${transaction.vendor}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (transaction.type == TransactionType.stokKeluar && transaction.customerName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Invoice: ${transaction.invoice} - ${transaction.customerName}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (transaction.type == TransactionType.sampah && transaction.jenisWaste != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Jenis: ${transaction.jenisWaste} - Kerugian: Rp ${_formatNumber(transaction.kerugian ?? '0')}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(String value) {
    try {
      final number = double.parse(value);
      return NumberFormat('#,###', 'id_ID').format(number);
    } catch (e) {
      return value;
    }
  }
}

// Transaction history model
enum TransactionType {
  stokMasuk,
  stokKeluar,
  sampah,
}

class TransactionHistory {
  final TransactionType type;
  final DateTime timestamp;
  final String itemName;
  final String quantity;
  final String unit;
  final String performedBy;

  // Optional fields for different types
  final String? vendor; // For stok masuk
  final String? totalPrice; // For stok masuk
  final String? invoice; // For stok keluar
  final String? customerName; // For stok keluar
  final String? jenisWaste; // For sampah
  final String? kerugian; // For sampah

  TransactionHistory({
    required this.type,
    required this.timestamp,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.performedBy,
    this.vendor,
    this.totalPrice,
    this.invoice,
    this.customerName,
    this.jenisWaste,
    this.kerugian,
  });
}

