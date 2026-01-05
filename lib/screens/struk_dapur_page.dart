// screens/struk_dapur_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StrukDapurPage extends StatefulWidget {
  final Map<String, dynamic> transaksi;
  final String userId;

  const StrukDapurPage({
    super.key,
    required this.transaksi,
    required this.userId,
  });

  @override
  State<StrukDapurPage> createState() => _StrukDapurPageState();
}

class _StrukDapurPageState extends State<StrukDapurPage> {
  Map<String, dynamic> _kedaiData = {};
  bool _isLoading = true;
  String _statusDapur = 'MENUNGGU'; // MENUNGGU, DIPROSES, SELESAI

  @override
  void initState() {
    super.initState();
    _loadKedaiData();
  }

  Future<void> _loadKedaiData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _kedaiData = {
        'nama_kedai': prefs.getString('nama_kedai_${widget.userId}') ?? 'KEDAI',
        'logo_kedai': prefs.getString('logo_kedai_${widget.userId}') ?? '',
      };
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatWaktuPesan() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${_formatDate(now)}';
  }

  // Hitung waktu estimasi selesai (rata-rata 10 menit per item)
  String _hitungEstimasiSelesai() {
    final totalItems = widget.transaksi['items'].fold(0, (sum, item) => sum + item['quantity']);
    final estimasiMenit = totalItems * 10;
    final now = DateTime.now();
    final estimasiSelesai = now.add(Duration(minutes: estimasiMenit));
    return _formatDate(estimasiSelesai);
  }

  // Kategori menu berdasarkan tipe (bisa disesuaikan dengan data asli)
  Map<String, List<dynamic>> _kategorikanItems() {
    final Map<String, List<dynamic>> kategori = {
      'MAKANAN': [],
      'MINUMAN': [],
      'LAINNYA': [],
    };

    for (var item in widget.transaksi['items']) {
      // Logic sederhana: jika mengandung kata tertentu, masuk kategori tertentu
      final nama = item['nama_menu'].toString().toLowerCase();
      if (nama.contains('nasi') || nama.contains('ayam') || nama.contains('mie') || 
          nama.contains('goreng') || nama.contains('bakar') || nama.contains('soto')) {
        kategori['MAKANAN']!.add(item);
      } else if (nama.contains('es') || nama.contains('teh') || nama.contains('kopi') || 
                 nama.contains('jus') || nama.contains('minum')) {
        kategori['MINUMAN']!.add(item);
      } else {
        kategori['LAINNYA']!.add(item);
      }
    }

    // Hapus kategori yang kosong
    kategori.removeWhere((key, value) => value.isEmpty);
    return kategori;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'MENUNGGU':
        return Colors.orange[800]!;
      case 'DIPROSES':
        return Colors.blue[800]!;
      case 'SELESAI':
        return Colors.green[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  Widget _buildLogoDapur() {
    if (_kedaiData['logo_kedai']?.toString().isEmpty == true) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.grey[100],
        ),
        child: Icon(Icons.restaurant, size: 25, color: Colors.grey),
      );
    }

    try {
      String base64String = _kedaiData['logo_kedai'].toString();
      
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }
      
      if (base64String.isEmpty) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[100],
          ),
          child: Icon(Icons.restaurant, size: 25, color: Colors.grey),
        );
      }
      
      final bytes = base64Decode(base64String);
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipOval(
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.grey[100],
        ),
        child: Icon(Icons.restaurant, size: 25, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategoriItems = _kategorikanItems();
    final totalItems = widget.transaksi['items'].fold(0, (sum, item) => sum + item['quantity']);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.orange[800],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ORDER DAPUR',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.print, color: Colors.white),
            onPressed: () {
              // TODO: Implement print untuk dapur
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header penting untuk dapur
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Logo dan nama kedai
                            Row(
                              children: [
                                _buildLogoDapur(),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _kedaiData['nama_kedai'].toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                    Text(
                                      'KITCHEN ORDER',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Status badge
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_statusDapur),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusDapur,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Info order penting
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'NO ORDER',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.transaksi['no_transaksi'].toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ],
                              ),
                              
                              Column(
                                children: [
                                  Text(
                                    'WAKTU ORDER',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatWaktuPesan(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              
                              Column(
                                children: [
                                  Text(
                                    'TOTAL ITEM',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$totalItems items',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Info customer dan meja
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: Colors.blue[700]),
                                  SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CUSTOMER',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        widget.transaksi['nama_pemesan'].toString(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              Row(
                                children: [
                                  Icon(Icons.table_restaurant, size: 16, color: Colors.blue[700]),
                                  SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MEJA',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        widget.transaksi['no_meja'].toString(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ESTIMASI',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _hitungEstimasiSelesai(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
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
                  
                  SizedBox(height: 8),
                  
                  // Daftar pesanan dengan kategori
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.only(top: 16, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(Icons.restaurant_menu, color: Colors.orange[800]),
                              SizedBox(width: 8),
                              Text(
                                'DAFTAR PESANAN',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$totalItems items',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Tampilkan per kategori
                        for (var kategori in kategoriItems.entries)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header kategori
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: _getKategoriColor(kategori.key),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getKategoriIcon(kategori.key),
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      kategori.key,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${kategori.value.length} item',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // List items dalam kategori
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Column(
                                  children: [
                                    for (var item in kategori.value)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Row(
                                          children: [
                                            // Quantity badge
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: Colors.orange[800],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${item['quantity']}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            SizedBox(width: 12),
                                            
                                            // Nama menu
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['nama_menu'].toString(),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey[800],
                                                    ),
                                                    maxLines: 2,
                                                  ),
                                                  SizedBox(height: 4),
                                                  // TODO: Jika ada catatan khusus per item
                                                  // Text(
                                                  //   'Tanpa bawang, pedas sedang',
                                                  //   style: GoogleFonts.poppins(
                                                  //     fontSize: 11,
                                                  //     color: Colors.red[600],
                                                  //     fontStyle: FontStyle.italic,
                                                  //   ),
                                                  // ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Status per item
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.green[200]!),
                                              ),
                                              child: Text(
                                                'READY',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              Divider(height: 1, color: Colors.grey[300]),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Catatan khusus untuk dapur
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.note, color: Colors.blue[800]),
                            SizedBox(width: 8),
                            Text(
                              'CATATAN KHUSUS',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            widget.transaksi['catatan_khusus']?.toString() ?? 
                            'Tidak ada catatan khusus',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.blue[900],
                              fontStyle: widget.transaksi['catatan_khusus'] != null 
                                  ? FontStyle.normal 
                                  : FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Tombol aksi untuk dapur
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _statusDapur = 'DIPROSES';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Order sedang diproses'),
                                  backgroundColor: Colors.blue[800],
                                ),
                              );
                            },
                            icon: Icon(Icons.play_arrow, size: 20),
                            label: Text(
                              'PROSES ORDER',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _statusDapur = 'SELESAI';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Order selesai diproses'),
                                  backgroundColor: Colors.green[800],
                                ),
                              );
                            },
                            icon: Icon(Icons.check, size: 20),
                            label: Text(
                              'SELESAI',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[800],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Footer timestamp
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    color: Colors.grey[200],
                    child: Text(
                      'Dicetak: ${_formatWaktuPesan()}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getKategoriColor(String kategori) {
    switch (kategori) {
      case 'MAKANAN':
        return Colors.orange[700]!;
      case 'MINUMAN':
        return Colors.blue[700]!;
      case 'LAINNYA':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getKategoriIcon(String kategori) {
    switch (kategori) {
      case 'MAKANAN':
        return Icons.restaurant;
      case 'MINUMAN':
        return Icons.local_drink;
      case 'LAINNYA':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}