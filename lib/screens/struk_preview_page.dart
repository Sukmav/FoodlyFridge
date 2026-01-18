// screens/struk_preview_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/kedai_service.dart';

class StrukPreviewPage extends StatefulWidget {
  final String userId;

  const StrukPreviewPage({super.key, required this.userId});

  @override
  State<StrukPreviewPage> createState() => _StrukPreviewPageState();
}

class _StrukPreviewPageState extends State<StrukPreviewPage> {
  Map<String, dynamic> _kedaiData = {
    'nama_kedai': 'KEDAI ANDA',
    'alamat_kedai': 'Alamat belum diisi',
    'nomor_telepon': '081234567890',
    'catatan_struk': 'Terima kasih atas kunjungan Anda',
    'logo_kedai': '',
  };
  
  bool _isLoading = true;
  final KedaiService _kedaiService = KedaiService();

  @override
  void initState() {
    super.initState();
    _loadKedaiData();
  }

  Future<void> _loadKedaiData() async {
    try {
      // Load dari KedaiService
      final kedai = await _kedaiService.getKedaiByUserId(widget.userId);

      if (kedai != null) {
        setState(() {
          _kedaiData = {
            'nama_kedai': kedai.nama_kedai,
            'alamat_kedai': kedai.alamat_kedai,
            'nomor_telepon': kedai.nomor_telepon,
            'catatan_struk': kedai.catatan_struk,
            'logo_kedai': kedai.logo_kedai,
          };
        });
      } else {
        // Fallback ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _kedaiData = {
            'nama_kedai': prefs.getString('nama_kedai_${widget.userId}') ?? 'KEDAI ANDA',
            'alamat_kedai': prefs.getString('alamat_kedai_${widget.userId}') ?? 'Alamat belum diisi',
            'nomor_telepon': prefs.getString('nomor_telepon_${widget.userId}') ?? '081234567890',
            'catatan_struk': prefs.getString('catatan_struk_${widget.userId}') ?? 'Terima kasih atas kunjungan Anda',
            'logo_kedai': prefs.getString('logo_kedai_${widget.userId}') ?? '',
          };
        });
      }
    } catch (e) {
      print('Error loading kedai data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildLogoPreview() {
    if (_kedaiData['logo_kedai']?.isEmpty == true) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.grey[100],
        ),
        child: const Icon(Icons.store, size: 30, color: Colors.grey),
      );
    }

    try {
      String base64String = _kedaiData['logo_kedai']!;
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipOval(
          child: Image.memory(
            base64Decode(base64String),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[100],
                child: const Icon(Icons.store, size: 30, color: Colors.grey),
              );
            },
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.grey[100],
        ),
        child: const Icon(Icons.store, size: 30, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pratinjau Struk',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ini adalah pratinjau template struk. Saat transaksi di kasir, struk akan menampilkan data aktual.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Struk Preview
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo
                            _buildLogoPreview(),
                            const SizedBox(height: 12),

                            // Nama Kedai
                            Text(
                              _kedaiData['nama_kedai'].toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),

                            // Alamat
                            Text(
                              _kedaiData['alamat_kedai'].toString(),
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            
                            // Telepon
                            if (_kedaiData['nomor_telepon'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Telp: ${_kedaiData['nomor_telepon']}',
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: 16),
                            const Divider(thickness: 1),
                            const SizedBox(height: 16),

                            // Info Transaksi Contoh
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('No: INV-20240118-001', style: TextStyle(fontSize: 12)),
                                Text('18/01/2024 14:30', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Nama: John Doe', style: TextStyle(fontSize: 12)),
                                Text('Meja: 05', style: TextStyle(fontSize: 12)),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Divider(thickness: 0.5),
                            const SizedBox(height: 16),

                            // Header Items
                            Row(
                              children: const [
                                Expanded(
                                  flex: 3,
                                  child: Text('ITEM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('QTY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('HARGA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Contoh Items
                            _buildItemRow('Nasi Goreng Special', 1, 25000),
                            _buildItemRow('Es Teh Manis', 2, 8000),
                            _buildItemRow('Kerupuk', 1, 5000),

                            const SizedBox(height: 16),
                            const Divider(thickness: 0.5),
                            const SizedBox(height: 16),

                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('TOTAL:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                Text('Rp 46.000', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Catatan Struk
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _kedaiData['catatan_struk'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Keterangan
                    Text(
                      'Struk di atas adalah contoh tampilan. Data aktual akan tampil saat transaksi di kasir.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildItemRow(String itemName, int qty, int price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(itemName, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: Text('$qty', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}', 
              style: const TextStyle(fontSize: 12), 
              textAlign: TextAlign.right
            ),
          ),
        ],
      ),
    );
  }
}