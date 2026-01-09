import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helpers/kedai_service.dart';
import '../model/kedai.dart';

class StrukPage extends StatefulWidget {
  final Map<String, dynamic> transaksi;
  final String userId;

  const StrukPage({
    Key? key,
    required this.transaksi,
    required this.userId,
  }) : super(key: key);

  @override
  State<StrukPage> createState() => _StrukPageState();
}

class _StrukPageState extends State<StrukPage> {
  Map<String, String> _kedaiData = {};
  bool _isLoading = true;

  // TAMBAHKAN KEDAI SERVICE
  final KedaiService _kedaiService = KedaiService();

  // State untuk save/export
  bool _isSavingImage = false;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadKedaiData();
  }

  Future<void> _loadKedaiData() async {
    try {
      print('=== LOADING KEDAI DATA FOR STRUK ===');
      print('User ID: ${widget.userId}');

      // **PRIORITAS 1: Ambil dari database via KedaiService**
      final kedai = await _kedaiService.getKedaiByUserId(widget.userId);

      if (kedai != null) {
        print('✅ Data found in database/cache via KedaiService');
        print('Nama Kedai: ${kedai.nama_kedai}');
        print('Alamat: ${kedai.alamat_kedai}');
        print('Telepon: ${kedai.nomor_telepon}');

        setState(() {
          _kedaiData = {
            'nama_kedai': kedai.nama_kedai,
            'alamat_kedai': kedai.alamat_kedai,
            'nomor_telepon': kedai.nomor_telepon,
            'catatan_struk': kedai.catatan_struk,
            'logo_kedai': kedai.logo_kedai,
          };
          _isLoading = false;
        });

        // **SIMPAN JUGA KE SHAREDPREFERENCES dengan format yang mudah diakses**
        await _saveToSimpleSharedPreferences(kedai);
        return;
      }

      print('⚠️ No data from KedaiService, checking SharedPreferences...');

      // **PRIORITAS 2: Cek SharedPreferences secara manual**
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Debug: Lihat semua key yang ada
      print('=== ALL KEYS IN SHAREDPREFERENCES ===');
      final allKeys = prefs.getKeys();
      for (var key in allKeys) {
        if (key.contains('kedai') || key.contains('cached') || key.contains('logo') || key.contains('nama')) {
          final value = prefs.getString(key);
          print('$key: ${value?.substring(0, value.length > 30 ? 30 : value.length)}...');
        }
      }

      // **Coba baca dari cached data format KedaiService**
      final cachedKey = 'cached_kedai_${widget.userId}';
      final cachedData = prefs.getString(cachedKey);

      if (cachedData != null) {
        try {
          final data = json.decode(cachedData);
          print('✅ Found cached data in KedaiService format');

          setState(() {
            _kedaiData = {
              'nama_kedai': data['nama_kedai'] ?? 'KEDAI ANDA',
              'alamat_kedai': data['alamat_kedai'] ?? 'Alamat belum diisi',
              'nomor_telepon': data['nomor_telepon'] ?? '08xxxxxxxxxx',
              'catatan_struk': data['catatan_struk'] ?? 'Terima kasih atas kunjungannya',
              'logo_kedai': data['logo_kedai'] ?? '',
            };
            _isLoading = false;
          });
          return;
        } catch (e) {
          print('❌ Error parsing cached data: $e');
        }
      }

      // **PRIORITAS 3: Cari dengan berbagai kemungkinan key**
      String? findData(String dataType) {
        // Coba beberapa format
        final possibleKeys = [
          '${dataType}_${widget.userId}',
          '${dataType}_default_owner_id',
          '${dataType}_default',
          dataType,
        ];

        for (var key in possibleKeys) {
          final value = prefs.getString(key);
          if (value != null && value.isNotEmpty) {
            print('📌 Found $dataType with key: $key');
            return value;
          }
        }

        print('❌ No $dataType found');
        return null;
      }

      final namaKedai = findData('nama_kedai') ?? 'KEDAI ANDA';
      final alamatKedai = findData('alamat_kedai') ?? 'Alamat belum diisi';
      final nomorTelepon = findData('nomor_telepon') ?? '08xxxxxxxxxx';
      final catatanStruk = findData('catatan_struk') ?? 'Terima kasih atas kunjungannya';
      final logoKedai = findData('logo_kedai') ?? '';

      setState(() {
        _kedaiData = {
          'nama_kedai': namaKedai,
          'alamat_kedai': alamatKedai,
          'nomor_telepon': nomorTelepon,
          'catatan_struk': catatanStruk,
          'logo_kedai': logoKedai,
        };
        _isLoading = false;
      });

      print('=== FINAL LOADED DATA ===');
      print('Nama Kedai: $namaKedai');
      print('Alamat: $alamatKedai');
      print('=========================');

    } catch (e) {
      print('❌ Error loading kedai data: $e');
      _loadDefaultData();
    }
  }

  // **Fungsi untuk menyimpan data ke SharedPreferences dengan format sederhana**
  Future<void> _saveToSimpleSharedPreferences(KedaiModel kedai) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Simpan dalam format sederhana (selain format cache KedaiService)
      await prefs.setString('nama_kedai', kedai.nama_kedai);
      await prefs.setString('alamat_kedai', kedai.alamat_kedai);
      await prefs.setString('nomor_telepon', kedai.nomor_telepon);
      await prefs.setString('catatan_struk', kedai.catatan_struk);
      await prefs.setString('logo_kedai', kedai.logo_kedai);

      // Simpan juga dengan userId
      await prefs.setString('nama_kedai_${widget.userId}', kedai.nama_kedai);
      await prefs.setString('alamat_kedai_${widget.userId}', kedai.alamat_kedai);

      print('✅ Simple data saved to SharedPreferences');
    } catch (e) {
      print('⚠️ Error saving to SharedPreferences: $e');
    }
  }

  void _loadDefaultData() {
    setState(() {
      _kedaiData = {
        'nama_kedai': 'KEDAI ANDA',
        'alamat_kedai': 'Alamat belum diisi',
        'nomor_telepon': '08xxxxxxxxxx',
        'catatan_struk': 'Terima kasih atas kunjungannya',
        'logo_kedai': '',
      };
      _isLoading = false;
    });
  }

  Future<void> _cetakStruk() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5),
        build: (pw.Context context) {
          return _buildPdfContent();
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );
  }

  Future<void> _saveAsImage() async {
    setState(() {
      _isSavingImage = true;
    });

    try {
      if (await _requestStoragePermission()) {
        final pdfBytes = await _generatePdfBytes();
        await _savePdfToGallery(pdfBytes);
        _showSnackBar('Struk berhasil disimpan ke galeri!');
      } else {
        _showSnackBar('Izin penyimpanan ditolak');
      }
    } catch (e) {
      print('Error saving image: $e');
      _showSnackBar('Error: $e');
    } finally {
      setState(() {
        _isSavingImage = false;
      });
    }
  }

  Future<void> _exportAsPdf() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5),
          build: (pw.Context context) {
            return _buildPdfContent();
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

    } catch (e) {
      print('Error generating PDF: $e');
      _showSnackBar('Gagal membuat PDF: $e');
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5),
        build: (pw.Context context) {
          return _buildPdfContent();
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _savePdfToGallery(Uint8List pdfBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/Struk_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      final result = await ImageGallerySaverPlus.saveFile(tempFile.path);

      if (result['isSuccess'] == true) {
        _showSnackBar('Struk berhasil disimpan ke galeri!');
      } else {
        _showSnackBar('Gagal menyimpan ke galeri');
      }

    } catch (e) {
      print('Error saving to gallery: $e');
      rethrow;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  pw.Widget _buildPdfContent() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Logo Kedai
        if (_kedaiData['logo_kedai']?.isNotEmpty == true)
          pw.Container(
            width: 40,
            height: 40,
            child: pw.ClipOval(
              child: pw.Image(
                pw.MemoryImage(
                  base64Decode(
                    _kedaiData['logo_kedai']!.contains(',')
                        ? _kedaiData['logo_kedai']!.split(',').last
                        : _kedaiData['logo_kedai']!,
                  ),
                ),
              ),
            ),
          ),

        pw.SizedBox(height: 8),

        // Nama Kedai
        pw.Text(
          _kedaiData['nama_kedai']!.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 4),

        // Alamat Kedai
        pw.Text(
          _kedaiData['alamat_kedai']!,
          style: const pw.TextStyle(fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),

        // Nomor Telepon
        pw.Text(
          'Telp: ${_kedaiData['nomor_telepon']!}',
          style: const pw.TextStyle(fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),

        // Info Transaksi
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'No: ${widget.transaksi['no_transaksi'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}'}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              _formatDate(DateTime.now()),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),

        pw.SizedBox(height: 4),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Nama: ${widget.transaksi['nama_pemesan'] ?? 'Pelanggan'}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Meja: ${widget.transaksi['no_meja'] ?? '-'}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),

        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.3),
        pw.SizedBox(height: 8),

        // Header tabel items
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text('ITEM', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('QTY', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text('HARGA', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
            ),
          ],
        ),

        pw.SizedBox(height: 4),

        // Items dari transaksi - PERBAIKI BAGIAN INI
        if (widget.transaksi['items'] != null && (widget.transaksi['items'] as List).isNotEmpty)
          for (var item in (widget.transaksi['items'] as List<dynamic>))
            pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        item['nama_menu']?.toString() ?? 'Item',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        '${item['quantity'] ?? 1}',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Rp ${_formatNumber(item['subtotal'] ?? 0)}',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
              ],
            )
        else
          pw.Text(
            'Tidak ada items',
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),

        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.3),
        pw.SizedBox(height: 8),

        // Total
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Rp ${_formatNumber(widget.transaksi['total_harga'] ?? 0)}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),

        pw.SizedBox(height: 12),

        // Catatan Struk
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            widget.transaksi['catatan'] ?? _kedaiData['catatan_struk']!,
            style:  pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatNumber(dynamic number) {
    double numValue;
    if (number is int) {
      numValue = number.toDouble();
    } else if (number is double) {
      numValue = number;
    } else if (number is String) {
      numValue = double.tryParse(number) ?? 0.0;
    } else {
      numValue = 0.0;
    }

    return numValue.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : Icon(icon, size: 18),
      label: Text(
        isLoading ? 'Processing...' : label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      ),
    );
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
        title: Text(
          'Struk Pembayaran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'image') _saveAsImage();
              if (value == 'pdf') _exportAsPdf();
              if (value == 'print') _cetakStruk();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'image',
                child: Row(
                  children: const [
                    Icon(Icons.image, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Save as Image'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: const [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'print',
                child: Row(
                  children: const [
                    Icon(Icons.print, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Print PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Panel Kontrol
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                children: [
                  // Informasi Struk
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Struk Transaksi',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  '${widget.transaksi['no_transaksi'] ?? 'INV-001'} - ${widget.transaksi['nama_pemesan'] ?? 'Pelanggan'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                Text(
                                  'Kedai: ${_kedaiData['nama_kedai']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tombol Aksi
                  Row(
                    children: [
                      // Save as Image
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.image,
                          label: 'Save Image',
                          color: Colors.blue,
                          isLoading: _isSavingImage,
                          onPressed: _saveAsImage,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Export PDF
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.picture_as_pdf,
                          label: 'Export PDF',
                          color: Colors.red,
                          isLoading: _isGeneratingPdf,
                          onPressed: _exportAsPdf,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Print PDF
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.print,
                          label: 'Print',
                          color: Colors.green,
                          isLoading: _isGeneratingPdf,
                          onPressed: _cetakStruk,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Preview Struk
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo Kedai
                      _buildLogoPreview(),

                      const SizedBox(height: 12),

                      // Nama Kedai
                      Text(
                        _kedaiData['nama_kedai']!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // Alamat Kedai
                      Text(
                        _kedaiData['alamat_kedai']!,
                        style: TextStyle(
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // Nomor Telepon
                      Text(
                        'Telp: ${_kedaiData['nomor_telepon']!}',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Garis pemisah
                      const Divider(thickness: 1, color: Colors.black),
                      const SizedBox(height: 12),

                      // Info Transaksi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'No: ${widget.transaksi['no_transaksi'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}'}',
                            style: TextStyle(
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            _formatDate(DateTime.now()),
                            style: TextStyle(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nama: ${widget.transaksi['nama_pemesan'] ?? 'Pelanggan'}',
                            style: TextStyle(
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Meja: ${widget.transaksi['no_meja'] ?? '-'}',
                            style: TextStyle(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Garis tipis
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 8),

                      // Header tabel
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'ITEM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'QTY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'HARGA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // List items
                      if (widget.transaksi['items'] != null && (widget.transaksi['items'] as List).isNotEmpty)
                        Column(
                          children: (widget.transaksi['items'] as List<dynamic>).map<Widget>((item) {
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        item['nama_menu']?.toString() ?? 'Item',
                                        style: TextStyle(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${item['quantity'] ?? 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Rp ${_formatNumber(item['subtotal'] ?? 0)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                            );
                          }).toList(),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Tidak ada items',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Garis tipis
                      const Divider(thickness: 0.5, color: Colors.grey),
                      const SizedBox(height: 12),

                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rp ${_formatNumber(widget.transaksi['total_harga'] ?? 0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Catatan Struk
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.transaksi['catatan'] ?? _kedaiData['catatan_struk']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Informasi tambahan
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fitur Ekspor:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoItem(
                    icon: Icons.image,
                    title: 'Save as Image',
                    description: 'Simpan struk sebagai PDF ke galeri foto',
                  ),

                  _buildInfoItem(
                    icon: Icons.picture_as_pdf,
                    title: 'Export as PDF',
                    description: 'Buat file PDF yang bisa dibagikan atau dicetak',
                  ),

                  _buildInfoItem(
                    icon: Icons.print,
                    title: 'Print PDF',
                    description: 'Cetak struk menggunakan printer sistem',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

      if (base64String.contains('/') || base64String.contains('\\')) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[100],
          ),
          child: const Icon(Icons.photo, size: 30, color: Colors.grey),
        );
      }

      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      if (base64String.isEmpty) {
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

      final bytes = base64Decode(base64String);
      return Container(
        width: 60,
        height: 60,
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
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.grey[100],
        ),
        child: const Icon(Icons.error, size: 30, color: Colors.grey),
      );
    }
  }

  Widget _buildInfoItem({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
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