// screens/struk_preview_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../model/stok_keluar.dart';
import '../helpers/kedai_service.dart';
import '../model/kedai.dart';

class StrukPreviewPage extends StatefulWidget {
  final String userId;

  const StrukPreviewPage({super.key, required this.userId});

  @override
  State<StrukPreviewPage> createState() => _StrukPreviewPageState();
}

class _StrukPreviewPageState extends State<StrukPreviewPage> {
  Map<String, dynamic> _kedaiData = {};
  bool _isLoading = true;

  // Data transaksi dari stok_keluar
  List<StokKeluarModel> _transactionList = [];
  StokKeluarModel? _selectedTransaction;

  // State untuk save/export
  bool _isSavingImage = false;
  bool _isGeneratingPdf = false;

  final KedaiService _kedaiService = KedaiService();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadKedaiData();
    await _loadTransactions();
  }

  Future<void> _loadKedaiData() async {
    try {
      print('=== LOADING KEDAI DATA FOR STRUK ===');
      print('User ID: ${widget.userId}');

      // Load from database via KedaiService
      final kedai = await _kedaiService.getKedaiByUserId(widget.userId);

      if (kedai != null) {
        print('✅ Data found in database/cache via KedaiService');

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
        // Fallback to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _kedaiData = {
            'nama_kedai': prefs.getString('nama_kedai_${widget.userId}') ?? 'KEDAI ANDA',
            'alamat_kedai': prefs.getString('alamat_kedai_${widget.userId}') ?? 'Alamat belum diisi',
            'nomor_telepon': prefs.getString('nomor_telepon_${widget.userId}') ?? '08xxxxxxxxxx',
            'catatan_struk': prefs.getString('catatan_struk_${widget.userId}') ?? 'Terima kasih atas kunjungan Anda',
            'logo_kedai': prefs.getString('logo_kedai_${widget.userId}') ?? '',
          };
        });
      }
    } catch (e) {
      print('Error loading kedai data: $e');
    }
  }

  Future<void> _loadTransactions() async {
    try {
      print('=== LOADING TRANSACTIONS FROM STOK KELUAR ===');

      final response = await http.post(
        Uri.parse('$fileUri/select/'),
        body: {
          'token': token,
          'project': project,
          'collection': 'stok_keluar',
          'appid': appid,
          'user_id': widget.userId,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final dynamic decodedData = json.decode(response.body);
        List<dynamic> dataList = [];

        if (decodedData is Map) {
          if (decodedData.containsKey('data')) {
            dataList = decodedData['data'] as List<dynamic>;
          } else {
            final keys = decodedData.keys.toList();
            for (var key in keys) {
              if (decodedData[key] is List) {
                dataList = decodedData[key] as List<dynamic>;
                break;
              }
            }
          }
        } else if (decodedData is List) {
          dataList = decodedData;
        }

        final List<StokKeluarModel> transactions = [];

        for (var item in dataList) {
          try {
            Map<String, dynamic> itemMap = {};
            if (item is Map) {
              item.forEach((key, value) {
                itemMap[key.toString()] = value;
              });
            }

            final stokKeluar = StokKeluarModel(
              id: (itemMap['_id']?.toString()) ?? DateTime.now().millisecondsSinceEpoch.toString(),
              invoice: (itemMap['invoice'] as String?) ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
              nama_pemesanan: (itemMap['nama_pemesanan'] as String?) ?? 'Tanpa Nama',
              no_meja: (itemMap['no_meja']?.toString()) ?? '-',
              tanggal: (itemMap['tanggal'] as String?) ?? DateTime.now().toString(),
              menu: (itemMap['menu'] as String?) ?? 'Tidak ada menu',
              catatan: (itemMap['catatan'] as String?),
              total_harga: (itemMap['total_harga'] as String?),
            );

            transactions.add(stokKeluar);
          } catch (e) {
            print('Error parsing transaction item: $e');
          }
        }

        // Sort by tanggal descending
        transactions.sort((a, b) => b.tanggal.compareTo(a.tanggal));

        setState(() {
          _transactionList = transactions;
          if (transactions.isNotEmpty) {
            _selectedTransaction = transactions.first; // Select most recent by default
          }
          _isLoading = false;
        });

        print('✅ Loaded ${transactions.length} transactions');
      } else {
        setState(() {
          _transactionList = [];
          _isLoading = false;
        });
        print('⚠️ No transactions found');
      }
    } catch (e) {
      print('❌ Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Parse menu string to list of items
  List<Map<String, dynamic>> _parseMenuItems(String menuString) {
    try {
      // Menu format: "Nasi Goreng x2<br>Es Teh x1"
      final items = menuString.split('<br>');
      final result = <Map<String, dynamic>>[];

      for (var item in items) {
        final trimmed = item.trim();
        if (trimmed.isEmpty) continue;

        // Parse "Nama Menu x Quantity"
        final match = RegExp(r'(.+?)\s+x\s*(\d+)', caseSensitive: false).firstMatch(trimmed);
        if (match != null) {
          final namaMenu = match.group(1)?.trim() ?? '';
          final qty = int.tryParse(match.group(2) ?? '1') ?? 1;

          result.add({
            'nama_menu': namaMenu,
            'quantity': qty,
          });
        }
      }

      return result;
    } catch (e) {
      print('Error parsing menu: $e');
      return [];
    }
  }

  // ========== FUNGSI SAVE/EXPORT ==========

  Future<void> _saveAsImage() async {
    if (_selectedTransaction == null) {
      _showSnackBar('Pilih transaksi terlebih dahulu');
      return;
    }

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
    if (_selectedTransaction == null) {
      _showSnackBar('Pilih transaksi terlebih dahulu');
      return;
    }

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
      final tempFile = File('${tempDir.path}/Struk_${_selectedTransaction!.invoice}_${DateTime.now().millisecondsSinceEpoch}.pdf');
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
    if (_selectedTransaction == null) {
      return pw.Center(child: pw.Text('Tidak ada transaksi'));
    }

    final menuItems = _parseMenuItems(_selectedTransaction!.menu);
    final totalHarga = double.tryParse(_selectedTransaction!.total_harga ?? '0') ?? 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (_kedaiData['logo_kedai']?.toString().isNotEmpty == true)
          pw.Container(
            width: 40,
            height: 40,
            child: pw.ClipOval(
              child: pw.Image(
                pw.MemoryImage(
                  base64Decode(
                    _kedaiData['logo_kedai'].toString().contains(',')
                        ? _kedaiData['logo_kedai'].toString().split(',').last
                        : _kedaiData['logo_kedai'].toString(),
                  ),
                ),
              ),
            ),
          ),

        pw.SizedBox(height: 8),

        pw.Text(
          _kedaiData['nama_kedai'].toString().toUpperCase(),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 4),

        pw.Text(
          _kedaiData['alamat_kedai'].toString(),
          style: const pw.TextStyle(fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),

        pw.Text(
          'Telp: ${_kedaiData['nomor_telepon'].toString()}',
          style: const pw.TextStyle(fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Invoice: ${_selectedTransaction!.invoice}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              _formatDate(_selectedTransaction!.tanggal),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),

        pw.SizedBox(height: 4),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Nama: ${_selectedTransaction!.nama_pemesanan}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Meja: ${_selectedTransaction!.no_meja}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),

        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.3),
        pw.SizedBox(height: 8),

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
          ],
        ),

        pw.SizedBox(height: 4),

        for (var item in menuItems)
          pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      item['nama_menu'].toString(),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '${item['quantity']}',
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
            ],
          ),

        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.3),
        pw.SizedBox(height: 8),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Rp ${_formatNumber(totalHarga)}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),

        pw.SizedBox(height: 12),

        if (_selectedTransaction!.catatan != null && _selectedTransaction!.catatan!.isNotEmpty && _selectedTransaction!.catatan != '-')
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Catatan:',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _selectedTransaction!.catatan!,
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),

        pw.SizedBox(height: 12),

        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            _kedaiData['catatan_struk'].toString(),
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ========== HELPER FUNCTIONS ==========

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

  String _formatDate(String dateString) {
    try {
      // Try to parse if it's a full DateTime string
      if (dateString.contains('-') && dateString.length > 10) {
        final date = DateTime.tryParse(dateString);
        if (date != null) {
          return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        }
      }
      // If it's already formatted, return as is
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ========== BUILD WIDGET ==========

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
          'Pratinjau & Export Struk',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_selectedTransaction != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'image') _saveAsImage();
                if (value == 'pdf') _exportAsPdf();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'image',
                  child: Row(
                    children: [
                      Icon(Icons.image, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Save as Image'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Export as PDF'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactionList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada transaksi',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Transaksi dari kasir akan muncul di sini',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Transaction Selector
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue[50],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih Transaksi:',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: DropdownButton<StokKeluarModel>(
                                isExpanded: true,
                                underline: const SizedBox(),
                                value: _selectedTransaction,
                                items: _transactionList.map((transaction) {
                                  return DropdownMenuItem<StokKeluarModel>(
                                    value: transaction,
                                    child: Text(
                                      '${transaction.invoice} - ${transaction.nama_pemesanan} (${_formatDate(transaction.tanggal)})',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTransaction = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Preview Struk
                      if (_selectedTransaction != null) ...[
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
                              child: _buildStrukPreview(),
                            ),
                          ),
                        ),

                        // Action Buttons
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSavingImage ? null : _saveAsImage,
                                  icon: _isSavingImage
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.image),
                                  label: Text('Save Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isGeneratingPdf ? null : _exportAsPdf,
                                  icon: _isGeneratingPdf
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.picture_as_pdf),
                                  label: Text('Export PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[700],
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildStrukPreview() {
    if (_selectedTransaction == null) {
      return const Center(child: Text('Tidak ada transaksi'));
    }

    final menuItems = _parseMenuItems(_selectedTransaction!.menu);
    final totalHarga = double.tryParse(_selectedTransaction!.total_harga ?? '0') ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo Kedai
        if (_kedaiData['logo_kedai']?.toString().isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLogoPreview(),
          ),

        // Nama Kedai
        Text(
          _kedaiData['nama_kedai'].toString().toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Alamat Kedai
        Text(
          _kedaiData['alamat_kedai'].toString(),
          style: GoogleFonts.poppins(
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),

        // Telepon
        Text(
          'Telp: ${_kedaiData['nomor_telepon'].toString()}',
          style: GoogleFonts.poppins(
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        // Invoice & Tanggal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Invoice: ${_selectedTransaction!.invoice}',
              style: GoogleFonts.poppins(fontSize: 11),
            ),
            Text(
              _formatDate(_selectedTransaction!.tanggal),
              style: GoogleFonts.poppins(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Nama & Meja
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nama: ${_selectedTransaction!.nama_pemesanan}',
              style: GoogleFonts.poppins(fontSize: 11),
            ),
            Text(
              'Meja: ${_selectedTransaction!.no_meja}',
              style: GoogleFonts.poppins(fontSize: 11),
            ),
          ],
        ),

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        // Header Tabel
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'ITEM',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'QTY',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Menu Items
        ...menuItems.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  item['nama_menu'].toString(),
                  style: GoogleFonts.poppins(fontSize: 11),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${item['quantity']}',
                  style: GoogleFonts.poppins(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        )),

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Rp ${_formatNumber(totalHarga)}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Catatan Transaksi
        if (_selectedTransaction!.catatan != null &&
            _selectedTransaction!.catatan!.isNotEmpty &&
            _selectedTransaction!.catatan != '-')
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.yellow[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan:',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedTransaction!.catatan!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),

        // Catatan Struk
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _kedaiData['catatan_struk'].toString(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
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
}

