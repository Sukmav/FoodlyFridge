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
//import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class StrukPreviewPage extends StatefulWidget {
  final String userId;

  const StrukPreviewPage({super.key, required this.userId});

  @override
  State<StrukPreviewPage> createState() => _StrukPreviewPageState();
}

class _StrukPreviewPageState extends State<StrukPreviewPage> {
  Map<String, dynamic> _kedaiData = {};
  bool _isLoading = true;
  
  
  // State untuk Bluetooth printing
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isPrinting = false;
  bool _isConnected = false;
  bool _bluetoothEnabled = false;
  
  // State untuk save/export
  bool _isSavingImage = false;
  bool _isGeneratingPdf = false;

  // Data contoh transaksi untuk preview
  final Map<String, dynamic> _contohTransaksi = {
    'no_transaksi': 'TRX-001',
    'nama_pemesan': 'John Doe',
    'no_meja': 'A01',
    'items': [
      {'nama_menu': 'Nasi Goreng Spesial', 'quantity': 2, 'subtotal': 50000.0},
      {'nama_menu': 'Es Teh Manis', 'quantity': 1, 'subtotal': 8000.0},
      {'nama_menu': 'Ayam Goreng', 'quantity': 1, 'subtotal': 25000.0},
    ],
    'total_harga': 83000.0,
  };

  @override
  void initState() {
    super.initState();
    _loadKedaiData();
    // _checkBluetoothStatus();
  }

  Future<void> _loadKedaiData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _kedaiData = {
        'nama_kedai': prefs.getString('nama_kedai_${widget.userId}') ?? 'KEDAI CONTOH',
        'alamat_kedai': prefs.getString('alamat_kedai_${widget.userId}') ?? 'Jl. Contoh No. 123',
        'nomor_telepon': prefs.getString('nomor_telepon_${widget.userId}') ?? '081234567890',
        'catatan_struk': prefs.getString('catatan_struk_${widget.userId}') ?? 'Terima kasih atas kunjungan Anda',
        'logo_kedai': prefs.getString('logo_kedai_${widget.userId}') ?? '',
      };
      _isLoading = false;
    });
  }

  // ========== FUNGSI PRINT VIA BLUETOOTH ==========
  
  Future<void> _printViaBluetooth() async {
    if (_isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            58 * PdfPageFormat.mm, // 🔥 STRUK 58mm
            double.infinity,
            marginAll: 5,
          ),
          build: (context) => _buildPdfContent(),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
      );

    } catch (e) {
      _showSnackBar('Gagal mencetak: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  
  // ========== GENERATE TEKS STRUK UNTUK PRINTER ==========
  
  String _generateStrukText() {
    const int width = 32; // Lebar struk thermal printer (32 karakter)
    final buffer = StringBuffer();
    
    // Initialize dengan kode karakter ESC/POS
    buffer.write('\x1B\x40'); // Initialize printer
    buffer.write('\x1B\x21\x00'); // Reset format teks
    
    // HEADER - Pusatkan dengan spasi
    final namaKedai = _kedaiData['nama_kedai'].toString().toUpperCase();
    final alamatKedai = _kedaiData['alamat_kedai'].toString();
    final telpKedai = 'Telp: ${_kedaiData['nomor_telepon']}';
    
    // Format nama kedai
    if (namaKedai.length <= width) {
      buffer.writeln(_centerText(namaKedai, width: width));
    } else {
      buffer.writeln(namaKedai);
    }
    
    // Alamat dengan wrap jika perlu
    _wrapText(alamatKedai, width, buffer);
    buffer.writeln(_centerText(telpKedai, width: width));
    
    // Garis pemisah
    buffer.writeln('=' * width);
    
    // INFO TRANSAKSI
    buffer.writeln('No   : ${_contohTransaksi['no_transaksi']}');
    buffer.writeln('Nama : ${_contohTransaksi['nama_pemesan']}');
    buffer.writeln('Meja : ${_contohTransaksi['no_meja']}');
    buffer.writeln('Tgl  : ${_formatDate(DateTime.now())}');
    
    buffer.writeln('-' * width);
    
    // HEADER TABEL - Format untuk alignment
    buffer.write('ITEM'.padRight(18));
    buffer.write('QTY'.padLeft(5));
    buffer.writeln('HARGA'.padLeft(9));
    
    buffer.writeln('-' * width);
    
    // ITEM BARANG
    for (var item in _contohTransaksi['items']) {
      final nama = item['nama_menu'].toString();
      final qty = item['quantity'].toString();
      final harga = 'Rp ${_formatNumber(item['subtotal'])}';
      
      // Handle nama item yang panjang
      if (nama.length > 18) {
        // Tulis nama di baris pertama
        buffer.write('${nama.substring(0, 18)}');
        buffer.write(qty.padLeft(5));
        buffer.writeln(harga.padLeft(9));
        
        // Tulis sisa nama di baris berikutnya
        final sisaNama = nama.substring(18);
        if (sisaNama.isNotEmpty) {
          final remainingWidth = width - 3; // Untuk indentasi
          if (sisaNama.length > remainingWidth) {
            buffer.writeln('  ${sisaNama.substring(0, remainingWidth)}');
          } else {
            buffer.writeln('  $sisaNama');
          }
        }
      } else {
        buffer.write(nama.padRight(18));
        buffer.write(qty.padLeft(5));
        buffer.writeln(harga.padLeft(9));
      }
    }
    
    // GARIS PEMISAH SEBELUM TOTAL
    buffer.writeln('-' * width);
    
    // TOTAL - Format teks tebal (ESC/POS command)
    buffer.write('\x1B\x45\x01'); // Set emphasized (bold) on
    buffer.write('TOTAL'.padRight(23));
    buffer.writeln(_formatNumber(_contohTransaksi['total_harga']).padLeft(9));
    buffer.write('\x1B\x45\x00'); // Set emphasized (bold) off
    
    buffer.writeln('=' * width);
    
    // CATATAN STRUK
    final catatan = _kedaiData['catatan_struk'].toString();
    _wrapText(catatan, width, buffer);
    
    // FOOTER
    buffer.writeln('');
    buffer.writeln(_centerText('Terima kasih', width: width));
    
    // Spasi untuk memastikan semua data tercetak
    buffer.writeln('\n\n\n');
    
    // Feed paper before cut
    buffer.write('\x1B\x64\x03'); // Feed 3 lines
    
    return buffer.toString();
  }
  
  void _wrapText(String text, int width, StringBuffer buffer) {
    if (text.isEmpty) return;
    
    if (text.length <= width) {
      buffer.writeln(_centerText(text, width: width));
      return;
    }
    
    final words = text.split(' ');
    var line = '';
    
    for (final word in words) {
      if ((line + word).length > width) {
        if (line.isNotEmpty) {
          buffer.writeln(_centerText(line.trim(), width: width));
        }
        line = word;
      } else {
        line = line.isEmpty ? word : '$line $word';
      }
    }
    
    if (line.isNotEmpty) {
      buffer.writeln(_centerText(line.trim(), width: width));
    }
  }
  
  String _centerText(String text, {int width = 32}) {
    if (text.length >= width) return text.substring(0, width);
    final padding = width - text.length;
    final leftPadding = (padding / 2).floor();
    final rightPadding = width - text.length - leftPadding;
    return (' ' * leftPadding) + text + (' ' * rightPadding);
  }

  // ========== FUNGSI SAVE/EXPORT ==========
  
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
              'No: ${_contohTransaksi['no_transaksi']}',
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
              'Nama: ${_contohTransaksi['nama_pemesan']}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Meja: ${_contohTransaksi['no_meja']}',
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
            pw.Expanded(
              flex: 2,
              child: pw.Text('HARGA', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        
        pw.SizedBox(height: 4),
        
        for (var item in _contohTransaksi['items'])
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
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Rp ${_formatNumber(item['subtotal'])}',
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.right,
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
              'Rp ${_formatNumber(_contohTransaksi['total_harga'])}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
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
            style:  pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'image') _saveAsImage();
              if (value == 'pdf') _exportAsPdf();
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
                value: 'printer',
                child: Row(
                  children: const [
                    Icon(Icons.print, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Print via Bluetooth'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Panel Kontrol
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[50],
                    child: Column(
                      children: [
                        
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
                            const SizedBox(height: 4),
                            
                            // Nomor Telepon
                            Text(
                              'Telp: ${_kedaiData['nomor_telepon'].toString()}',
                              style: GoogleFonts.poppins(
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
                                  'No: ${_contohTransaksi['no_transaksi']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  _formatDate(DateTime.now()),
                                  style: GoogleFonts.poppins(
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
                                  'Nama: ${_contohTransaksi['nama_pemesan']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'Meja: ${_contohTransaksi['no_meja']}',
                                  style: GoogleFonts.poppins(
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
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'HARGA',
                                    style: GoogleFonts.poppins(
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
                            for (var item in _contohTransaksi['items'] as List<dynamic>)
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          item['nama_menu'].toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          item['quantity'].toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Rp ${_formatNumber(item['subtotal'])}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                ],
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
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Rp ${_formatNumber(_contohTransaksi['total_harga'])}',
                                  style: GoogleFonts.poppins(
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
                                _kedaiData['catatan_struk'].toString(),
                                style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
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
                          title: 'Bluetooth Print',
                          description: 'Cetak langsung ke printer thermal Bluetooth',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

  Widget _buildLogoPreview() {
    if (_kedaiData['logo_kedai']?.toString().isEmpty == true) {
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
      String base64String = _kedaiData['logo_kedai'].toString();
      
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
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
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