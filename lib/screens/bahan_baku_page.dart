import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import '../restapi.dart';
import '../config.dart';
import '../model/bahan_baku_model.dart';
import '../helpers/image_helper.dart';
import 'package:intl/intl.dart';

class BahanBakuPage extends StatefulWidget {
  const BahanBakuPage({super.key});

  @override
  State<BahanBakuPage> createState() => _BahanBakuPageState();
}

class _BahanBakuPageState extends State<BahanBakuPage> {
  final DataService _dataService = DataService();
  List<BahanBakuModel> _bahanBakuList = [];
  List<BahanBakuModel> _filteredList = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<String> _kategoriList = [];

  @override
  void initState() {
    super.initState();
    _loadBahanBaku();
    _loadKategori();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    setState(() {
      _kategoriList = [];
    });
  }

  void _saveKategori(String kategori) {
    if (!_kategoriList.contains(kategori)) {
      setState(() {
        _kategoriList.add(kategori);
      });
    }
  }

  Future<void> _loadBahanBaku() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== LOADING DATA ===');
      final response = await _dataService.selectAll(
        token,
        project,
        'bahan_baku',
        appid,
      );

      print('Response: $response');

      if (response == '[]' || response.isEmpty || response == 'null') {
        print('Data kosong atau null');
        setState(() {
          _bahanBakuList = [];
          _filteredList = [];
          _isLoading = false;
        });
        return;
      }

      final dynamic decodedData = json.decode(response);
      List<dynamic> dataList;

      if (decodedData is Map) {
        if (decodedData.containsKey('data')) {
          dataList = decodedData['data'] as List<dynamic>;
        } else {
          dataList = [decodedData];
        }
      } else if (decodedData is List) {
        dataList = decodedData;
      } else {
        dataList = [];
      }

      print('Jumlah data yang dimuat: ${dataList.length}');

      final newList = dataList.map((json) => BahanBakuModel.fromJson(json)).toList();

      setState(() {
        _bahanBakuList = newList;
        _filteredList = List.from(_bahanBakuList);
        _isLoading = false;
      });

      print('Data berhasil dimuat: ${_bahanBakuList.length} items');

    } catch (e, stackTrace) {
      print('Error: $e');
      print('StackTrace: $stackTrace');

      setState(() {
        _bahanBakuList = [];
        _filteredList = [];
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Gagal memuat data: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  void _filterBahanBaku(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _bahanBakuList;
      } else {
        _filteredList = _bahanBakuList
            .where((bahan) =>
        bahan.nama_bahan.toLowerCase().contains(query.toLowerCase()) ||
            bahan.kategori.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Helper untuk menghitung tanggal kadaluarsa
  String _calculateExpiryDate(String tanggalMasuk, String estimasiUmur) {
    try {
      if (tanggalMasuk.isEmpty || estimasiUmur.isEmpty) return '';

      final masuk = DateFormat('yyyy-MM-dd').parse(tanggalMasuk);
      final hari = int.tryParse(estimasiUmur) ?? 0;

      if (hari <= 0) return '';

      final kadaluarsa = masuk.add(Duration(days: hari));
      return DateFormat('yyyy-MM-dd').format(kadaluarsa);
    } catch (e) {
      print('Error calculating expiry: $e');
      return '';
    }
  }

  void _showAddEditDialog({BahanBakuModel? bahanBaku}) {
    final bool isEdit = bahanBaku != null;

    final TextEditingController namaBahanController = TextEditingController(text: bahanBaku?.nama_bahan ?? '');
    final TextEditingController unitController = TextEditingController(text: bahanBaku?.unit ?? '');
    final TextEditingController grossQtyController = TextEditingController(text: bahanBaku?.gross_qty ?? '');
    final TextEditingController hargaPerGrossController = TextEditingController(text: bahanBaku?.harga_per_gross ?? '');
    final TextEditingController hargaPerUnitController = TextEditingController(text: bahanBaku?.harga_per_unit ?? '');
    final TextEditingController stokTersediaController = TextEditingController(text: bahanBaku?.stok_tersedia ?? '');
    final TextEditingController estimasiUmurController = TextEditingController(text: bahanBaku?.estimasi_umur ?? '');
    final TextEditingController kategoriController = TextEditingController(text: bahanBaku?.kategori ?? '');
    final TextEditingController tempatPenyimpananController = TextEditingController(text: bahanBaku?.tempat_penyimpanan ?? '');
    final TextEditingController catatanController = TextEditingController(text: bahanBaku?.catatan ?? '');

    // Untuk tanggal, gunakan DateTime dan tampilkan di TextField
    DateTime? selectedTanggalMasuk = bahanBaku?.tanggal_masuk != null && bahanBaku!.tanggal_masuk.isNotEmpty
        ? DateTime.tryParse(bahanBaku.tanggal_masuk)
        : null;

    final TextEditingController tanggalMasukController = TextEditingController(
      text: selectedTanggalMasuk != null
          ? DateFormat('yyyy-MM-dd').format(selectedTanggalMasuk)
          : ''
    );

    // Tanggal kadaluarsa akan dihitung otomatis
    final TextEditingController tanggalKadaluarsaController = TextEditingController(
      text: bahanBaku?.tanggal_kadaluarsa ?? ''
    );

    // Variable untuk menyimpan gambar yang dipilih
    File? selectedImage;
    String? selectedImagePath = bahanBaku?.foto_bahan;

    // Fungsi untuk update tanggal kadaluarsa otomatis
    void updateTanggalKadaluarsa() {
      final tanggalMasuk = tanggalMasukController.text;
      final estimasi = estimasiUmurController.text;
      final kadaluarsa = _calculateExpiryDate(tanggalMasuk, estimasi);
      tanggalKadaluarsaController.text = kadaluarsa;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Widget untuk preview dan upload gambar
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final imageFile = await ImageHelper.showImageSourceDialog(context);
                              if (imageFile != null) {
                                setDialogState(() {
                                  selectedImage = imageFile;
                                  if (kIsWeb) {
                                    selectedImagePath = imageFile.path;
                                  }
                                });
                              }
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFB53929), width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildImagePreview(selectedImage, selectedImagePath),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFB53929),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Tap untuk memilih/mengambil gambar',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Utama',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFFB53929),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Divider(color: Color(0xFFB53929), thickness: 1),
                          const SizedBox(height: 16),
                          _buildStyledTextField(namaBahanController, 'Nama Bahan'),
                          const SizedBox(height: 16),
                          _buildStyledTextField(unitController, 'Unit/Satuan'),
                          const SizedBox(height: 16),
                          _buildStyledTextField(grossQtyController, 'Gross Quantity', TextInputType.number),
                          const SizedBox(height: 16),
                          _buildStyledTextField(hargaPerGrossController, 'Harga Per Gross', TextInputType.number),
                          const SizedBox(height: 16),
                          _buildStyledTextField(hargaPerUnitController, 'Harga Per Unit', TextInputType.number),
                          const SizedBox(height: 24),
                          Text(
                            'Stok',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFFB53929),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Divider(color: Color(0xFFB53929), thickness: 1),
                          const SizedBox(height: 16),
                          _buildStyledTextField(stokTersediaController, 'Stok Tersedia', TextInputType.number),
                          const SizedBox(height: 24),
                          Text(
                            'Tanggal dan Penyimpanan',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFFB53929),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Divider(color: Color(0xFFB53929), thickness: 1),
                          const SizedBox(height: 16),
                          // Tanggal Masuk dengan Date Picker
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedTanggalMasuk ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedTanggalMasuk = picked;
                                  tanggalMasukController.text = DateFormat('yyyy-MM-dd').format(picked);
                                  updateTanggalKadaluarsa();
                                });
                              }
                            },
                            child: IgnorePointer(
                              child: _buildStyledTextField(
                                tanggalMasukController,
                                'Tanggal Masuk',
                                null,
                                Icons.calendar_today,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Estimasi Umur dengan keterangan "hari" otomatis
                          TextField(
                            controller: estimasiUmurController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setDialogState(() {
                                updateTanggalKadaluarsa();
                              });
                            },
                            style: GoogleFonts.poppins(),
                            decoration: InputDecoration(
                              hintText: 'Estimasi Umur Simpan',
                              hintStyle: GoogleFonts.poppins(),
                              suffixText: 'hari',
                              suffixStyle: GoogleFonts.poppins(
                                color: const Color(0xFFB53929),
                                fontWeight: FontWeight.w500,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFB53929)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFB53929)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFB53929), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Tanggal Kadaluarsa (read-only, otomatis)
                          IgnorePointer(
                            child: TextField(
                              controller: tanggalKadaluarsaController,
                              style: GoogleFonts.poppins(),
                              decoration: InputDecoration(
                                hintText: 'Tanggal Kadaluarsa (Otomatis)',
                                hintStyle: GoogleFonts.poppins(),
                                suffixIcon: const Icon(Icons.lock, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFB53929)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _showKategoriDialog(kategoriController),
                            child: IgnorePointer(
                              child: _buildStyledTextField(
                                kategoriController,
                                'Pilih Kategori',
                                null,
                                Icons.arrow_drop_down,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStyledTextField(tempatPenyimpananController, 'Tempat Penyimpanan'),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFB53929)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    'Catatan Tambahan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFFB53929),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  child: TextField(
                                    controller: catatanController,
                                    maxLines: 3,
                                    style: GoogleFonts.poppins(),
                                    decoration: InputDecoration(
                                      hintText: 'Tambahkan catatan...',
                                      hintStyle: GoogleFonts.poppins(fontSize: 14),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (namaBahanController.text.isEmpty) {
                                  Fluttertoast.showToast(
                                    msg: "Nama bahan harus diisi!",
                                    backgroundColor: Colors.red,
                                  );
                                  return;
                                }

                                // Proses upload gambar jika ada
                                String imageUrl = '';

                                if (selectedImage != null) {
                                  try {
                                    Fluttertoast.showToast(
                                      msg: "Memproses gambar...",
                                      backgroundColor: Colors.blue,
                                    );

                                    print('=== MULAI PROSES UPLOAD GAMBAR ===');
                                    print('File gambar: ${selectedImage!.path}');

                                    if (!kIsWeb) {
                                      final localPath = await ImageHelper.saveImageToAssets(
                                        selectedImage!,
                                        namaBahanController.text.replaceAll(' ', '_'),
                                      );

                                      if (localPath != null) {
                                        imageUrl = localPath;
                                        print('✓ Gambar disimpan lokal: $localPath');
                                      }
                                    }

                                    print('Mencoba upload ke GoCloud...');
                                    final cloudUrl = await ImageHelper.uploadImageToGoCloud(
                                      imageFile: selectedImage!,
                                      token: token,
                                      project: project,
                                      fileName: namaBahanController.text.replaceAll(' ', '_'),
                                    );

                                    if (cloudUrl != null && cloudUrl.isNotEmpty) {
                                      imageUrl = cloudUrl;
                                      print('✓ Gambar berhasil diupload ke cloud: $cloudUrl');
                                      Fluttertoast.showToast(
                                        msg: "Gambar berhasil diupload!",
                                        backgroundColor: Colors.green,
                                      );
                                    } else {
                                      print('Upload ke cloud gagal, menggunakan Base64...');

                                      final base64Image = await ImageHelper.convertImageToBase64(selectedImage!);

                                      if (base64Image != null && base64Image.isNotEmpty) {
                                        imageUrl = base64Image;
                                        print('✓ Gambar berhasil dikonversi ke Base64');
                                        Fluttertoast.showToast(
                                          msg: kIsWeb
                                              ? "Gambar disimpan sebagai Base64"
                                              : "Gambar disimpan lokal",
                                          backgroundColor: Colors.green,
                                        );
                                      } else {
                                        print('✗ Konversi Base64 gagal');
                                        if (kIsWeb) {
                                          Fluttertoast.showToast(
                                            msg: "Gagal memproses gambar",
                                            backgroundColor: Colors.orange,
                                          );
                                          imageUrl = '';
                                        }
                                      }
                                    }

                                    print('URL gambar final: ${imageUrl.length > 100 ? imageUrl.substring(0, 100) + "..." : imageUrl}');
                                  } catch (e) {
                                    print('✗ Error memproses gambar: $e');
                                    Fluttertoast.showToast(
                                      msg: "Error memproses gambar: $e",
                                      backgroundColor: Colors.red,
                                    );
                                    imageUrl = '';
                                  }
                                } else {
                                  if (isEdit && bahanBaku.foto_bahan.isNotEmpty) {
                                    imageUrl = bahanBaku.foto_bahan;
                                  } else {
                                    imageUrl = '';
                                  }
                                }

                                Navigator.pop(context);

                                if (isEdit) {
                                  await _updateBahanBaku(
                                    bahanBaku.id,
                                    namaBahanController.text,
                                    imageUrl,
                                    unitController.text,
                                    grossQtyController.text,
                                    hargaPerGrossController.text,
                                    hargaPerUnitController.text,
                                    stokTersediaController.text,
                                    estimasiUmurController.text,
                                    tanggalMasukController.text,
                                    tanggalKadaluarsaController.text,
                                    kategoriController.text,
                                    tempatPenyimpananController.text,
                                    catatanController.text,
                                    bahanBaku.nama_bahan,
                                  );
                                } else {
                                  await _addBahanBaku(
                                    namaBahanController.text,
                                    imageUrl,
                                    unitController.text,
                                    grossQtyController.text,
                                    hargaPerGrossController.text,
                                    hargaPerUnitController.text,
                                    stokTersediaController.text,
                                    estimasiUmurController.text,
                                    tanggalMasukController.text,
                                    tanggalKadaluarsaController.text,
                                    kategoriController.text,
                                    tempatPenyimpananController.text,
                                    catatanController.text,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB53929),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Simpan',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method untuk menampilkan preview gambar yang mendukung Web dan Mobile
  Widget _buildImagePreview(File? selectedImage, String? imagePath) {
    if (selectedImage != null && !kIsWeb) {
      // Mobile: Gunakan Image.file
      return Image.file(
        selectedImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.inventory_2,
            size: 50,
            color: Colors.grey,
          );
        },
      );
    } else if (imagePath != null && imagePath.isNotEmpty) {
      // Web atau path dari database
      if (imagePath.startsWith('http')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.inventory_2,
              size: 50,
              color: Colors.grey,
            );
          },
        );
      } else if (!kIsWeb) {
        // Mobile: path lokal
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.inventory_2,
              size: 50,
              color: Colors.grey,
            );
          },
        );
      }
    }

    // Default: tampilkan icon
    return const Icon(
      Icons.inventory_2,
      size: 50,
      color: Colors.grey,
    );
  }

  Widget _buildStyledTextField(
      TextEditingController controller,
      String hint, [
        TextInputType? keyboardType,
        IconData? suffixIcon,
      ]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB53929)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB53929)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB53929), width: 2),
        ),
      ),
    );
  }

  void _showKategoriDialog(TextEditingController kategoriController) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFB53929),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Pilih Kategori',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _kategoriList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _kategoriList.length) {
                      return ListTile(
                        leading: const Icon(Icons.add, color: Color(0xFFB53929)),
                        title: Text('Tambah Kategori Baru', style: GoogleFonts.poppins()),
                        onTap: () {
                          Navigator.pop(context);
                          _showTambahKategoriDialog(kategoriController);
                        },
                      );
                    }
                    return ListTile(
                      title: Text(_kategoriList[index], style: GoogleFonts.poppins()),
                      onTap: () {
                        kategoriController.text = _kategoriList[index];
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTambahKategoriDialog(TextEditingController kategoriController) {
    final TextEditingController newKategoriController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tambah Kategori Baru',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: newKategoriController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'Nama Kategori',
                  hintStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (newKategoriController.text.isNotEmpty) {
                      _saveKategori(newKategoriController.text);
                      kategoriController.text = newKategoriController.text;
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB53929),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Simpan', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addBahanBaku(
      String namaBahan,
      String fotoBahan,
      String unit,
      String grossQty,
      String hargaPerGross,
      String hargaPerUnit,
      String stokTersedia,
      String estimasiUmur,
      String tanggalMasuk,
      String tanggalKadaluarsa,
      String kategori,
      String tempatPenyimpanan,
      String catatan,
      ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== MULAI INSERT ===');
      final result = await _dataService.insertBahanBaku(
        appid,
        fotoBahan,
        namaBahan,
        unit,
        grossQty,
        hargaPerGross,
        hargaPerUnit,
        stokTersedia,
        estimasiUmur,
        tanggalMasuk,
        tanggalKadaluarsa,
        kategori,
        tempatPenyimpanan,
        catatan,
      );

      print('Result insert: $result');

      await Future.delayed(const Duration(milliseconds: 500));
      await _loadBahanBaku();

      Fluttertoast.showToast(
        msg: "Bahan baku '$namaBahan' berhasil ditambahkan!",
        backgroundColor: Colors.green,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: "Gagal menambahkan: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _updateBahanBaku(
      String id,
      String namaBahan,
      String fotoBahan,
      String unit,
      String grossQty,
      String hargaPerGross,
      String hargaPerUnit,
      String stokTersedia,
      String estimasiUmur,
      String tanggalMasuk,
      String tanggalKadaluarsa,
      String kategori,
      String tempatPenyimpanan,
      String catatan,
      String namaLama,
      ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== MULAI UPDATE BAHAN BAKU ===');
      print('ID: $id');
      print('Nama Lama: $namaLama');
      print('Nama Baru: $namaBahan');

      if (id.isEmpty || id == '') {
        print('ID kosong, menggunakan updateWhere berdasarkan nama');

        final fields = {
          'nama_bahan': namaBahan,
          'foto_bahan': fotoBahan,
          'unit': unit,
          'gross_qty': grossQty,
          'harga_per_gross': hargaPerGross,
          'harga_per_unit': hargaPerUnit,
          'stok_tersedia': stokTersedia,
          'estimasi_umur': estimasiUmur,
          'tanggal_masuk': tanggalMasuk,
          'tanggal_kadaluarsa': tanggalKadaluarsa,
          'kategori': kategori,
          'tempat_penyimpanan': tempatPenyimpanan,
          'catatan': catatan,
        };

        for (var entry in fields.entries) {
          final result = await _dataService.updateWhere(
            'nama_bahan',
            namaLama,
            entry.key,
            entry.value,
            token,
            project,
            'bahan_baku',
            appid,
          );
          print('Update ${entry.key}: $result');
        }
      } else {
        print('Menggunakan updateId');

        final results = await Future.wait([
          _dataService.updateId('nama_bahan', namaBahan, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('foto_bahan', fotoBahan, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('unit', unit, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('gross_qty', grossQty, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('harga_per_gross', hargaPerGross, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('harga_per_unit', hargaPerUnit, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('stok_tersedia', stokTersedia, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('estimasi_umur', estimasiUmur, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('tanggal_masuk', tanggalMasuk, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('tanggal_kadaluarsa', tanggalKadaluarsa, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('kategori', kategori, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('tempat_penyimpanan', tempatPenyimpanan, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('catatan', catatan, token, project, 'bahan_baku', appid, id),
        ]);

        print('Update results: $results');
      }

      print('✓ Update berhasil di API');

      await _loadBahanBaku();

      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Bahan baku '$namaBahan' berhasil diupdate!",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_SHORT,
      );

      print('=== SELESAI UPDATE ===');

    } catch (e, stackTrace) {
      print('=== ERROR UPDATE ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Gagal mengupdate: ${e.toString()}",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );

      await _loadBahanBaku();
    }
  }

  Future<void> _deleteBahanBaku(String id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hapus Bahan Baku?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin menghapus "$nama"? Data yang dihapus tidak dapat dikembalikan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Batal', style: GoogleFonts.poppins()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      print('=== MULAI DELETE BAHAN BAKU ===');
      print('ID yang akan dihapus: $id');
      print('Nama bahan: $nama');

      final result = await _dataService.removeWhere(
        token,
        project,
        'bahan_baku',
        appid,
        'nama_bahan',
        nama,
      );

      print('Result delete dari API: $result');

      if (result == true || result == 'true' || result.toString().contains('"status":"1"')) {
        print('✓ Delete berhasil di database!');

        setState(() {
          _bahanBakuList.removeWhere((item) => item.nama_bahan == nama);
          _filteredList.removeWhere((item) => item.nama_bahan == nama);
        });

        Fluttertoast.showToast(
          msg: "Bahan baku '$nama' berhasil dihapus!",
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT,
        );

        print('✓ Data berhasil dihapus dari tampilan');
      } else {
        print('✗ Delete gagal: $result');
        throw Exception('Delete gagal: $result');
      }

      print('=== SELESAI DELETE ===');

    } catch (e, stackTrace) {
      print('=== ERROR DELETE ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      Fluttertoast.showToast(
        msg: "Gagal menghapus bahan baku: ${e.toString()}",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );

      await _loadBahanBaku();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterBahanBaku,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                hintText: 'Cari bahan baku...',
                hintStyle: GoogleFonts.poppins(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFB53929), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada data bahan baku',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredList.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final bahan = _filteredList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB53929).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageWidget(bahan.foto_bahan),
                      ),
                    ),
                    title: Text(
                      bahan.nama_bahan,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Stok: ${bahan.stok_tersedia} ${bahan.unit}',
                          style: GoogleFonts.poppins(),
                        ),
                        Text(
                          'Kategori: ${bahan.kategori}',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddEditDialog(bahanBaku: bahan),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBahanBaku(bahan.id, bahan.nama_bahan),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah', style: GoogleFonts.poppins(color: Colors.white)),
      ),
    );
  }

  // Helper method untuk menampilkan gambar yang mendukung Web dan Mobile
  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('http')) {
      // URL gambar
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.inventory_2,
            color: Color(0xFFB53929),
          );
        },
      );
    } else if (imagePath.startsWith('data:image')) {
      // Base64 image
      return Image.memory(
        base64Decode(imagePath.split(',').last),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.inventory_2,
            color: Color(0xFFB53929),
          );
        },
      );
    } else {
      // Path lokal (mobile)
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.inventory_2,
            color: Color(0xFFB53929),
          );
        },
      );
    }
  }
}
