import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../restapi.dart';
import '../config.dart';
import '../model/bahan_baku_model.dart';
import '../helpers/image_helper.dart';

class BahanBakuPage extends StatefulWidget {
  const BahanBakuPage({super.key});

  @override
  State<BahanBakuPage> createState() => _BahanBakuPageState();
}

class _BahanBakuPageState extends State<BahanBakuPage> {
  final DataService _data_service = DataService();
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
      if (kDebugMode) print('=== LOADING DATA ===');
      final response = await _data_service.selectAll(
        token,
        project,
        'bahan_baku',
        appid,
      );

      if (kDebugMode) print('Response: $response');

      if (response == '[]' || response.isEmpty || response == 'null') {
        if (kDebugMode) print('Data kosong atau null');
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

      if (kDebugMode) print('Jumlah data yang dimuat: ${dataList.length}');

      final newList = dataList.map((json) => BahanBakuModel.fromJson(json)).toList();

      setState(() {
        _bahanBakuList = newList;
        _filteredList = List.from(_bahanBakuList);
        _isLoading = false;
      });

      if (kDebugMode) print('Data berhasil dimuat: ${_bahanBakuList.length} items');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error: $e');
        print('StackTrace: $stackTrace');
      }

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

  void _showAddEditDialog({BahanBakuModel? bahanBaku}) {
    final bool isEdit = bahanBaku != null;

    final TextEditingController namaController = TextEditingController(text: bahanBaku?.nama_bahan ?? '');
    String selectedUnit = bahanBaku?.unit ?? 'kg';
    final TextEditingController hargaGrossController = TextEditingController(text: bahanBaku?.harga_per_gross ?? '');
    final TextEditingController hargaUnitController = TextEditingController(text: bahanBaku?.harga_per_unit ?? '');
    final TextEditingController stokTersediaController = TextEditingController(text: bahanBaku?.stok_tersedia ?? '');
    String stokMinimal = bahanBaku?.stok_minimal ?? '5';
    final TextEditingController estimasiUmurController = TextEditingController(text: bahanBaku?.estimasi_umur ?? '');
    DateTime? tanggalMasuk = bahanBaku?.tanggal_masuk != null && bahanBaku!.tanggal_masuk.isNotEmpty
        ? DateTime.tryParse(bahanBaku.tanggal_masuk)
        : null;
    DateTime? tanggalKadaluarsa = bahanBaku?.tanggal_kadaluarsa != null && bahanBaku!.tanggal_kadaluarsa.isNotEmpty
        ? DateTime.tryParse(bahanBaku.tanggal_kadaluarsa)
        : null;
    final TextEditingController kategoriController = TextEditingController(text: bahanBaku?.kategori ?? '');
    final TextEditingController tempatPenyimpananController = TextEditingController(text: bahanBaku?.tempat_penyimpanan ?? '');
    final TextEditingController grossQtyController = TextEditingController(text: bahanBaku?.gross_qty ?? '');
    final TextEditingController catatanController = TextEditingController(text: bahanBaku?.catatan ?? '');

    // Variable untuk menyimpan gambar yang dipilih
    // selectedImage may be File (mobile) or Uint8List (web bytes) or XFile
    dynamic selectedImage;
    String? selectedImagePath = bahanBaku?.foto_bahan;

    String getStokMinimalByUnit(String unit) {
      switch (unit) {
        case 'kg':
          return '5';
        case 'gr':
          return '1000';
        case 'dus':
          return '5';
        default:
          return '5';
      }
    }

    DateTime? calculateExpiryDate(DateTime? startDate, String estimasi) {
      if (startDate == null || estimasi.isEmpty) return null;
      try {
        int days = int.parse(estimasi);
        return startDate.add(Duration(days: days));
      } catch (e) {
        return null;
      }
    }

    stokMinimal = getStokMinimalByUnit(selectedUnit);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: Text(isEdit ? 'Edit Data' : 'Tambah Data'),
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Upload Gambar
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final dynamic imageFile = await ImageHelper.showImageSourceDialog(context);
                          if (imageFile == null) return;

                          if (kIsWeb) {
                            try {
                              Uint8List bytes;
                              if (imageFile is XFile) {
                                bytes = await imageFile.readAsBytes();
                              } else if (imageFile is Uint8List) {
                                bytes = imageFile;
                              } else if (imageFile is List<int>) {
                                bytes = Uint8List.fromList(imageFile.cast<int>());
                              } else if (imageFile is File) {
                                bytes = await imageFile.readAsBytes();
                              } else {
                                final path = imageFile?.path;
                                if (path != null) {
                                  bytes = await File(path).readAsBytes();
                                } else {
                                  bytes = Uint8List(0);
                                }
                              }

                              if (bytes.isNotEmpty) {
                                final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
                                if (kDebugMode) print('[IMAGE] web selected bytes=${bytes.length}');
                                setDialogState(() {
                                  selectedImage = bytes;
                                  selectedImagePath = dataUrl;
                                });
                              }
                            } catch (e) {
                              if (kDebugMode) print('[IMAGE] error reading web image: $e');
                            }
                          } else {
                            try {
                              if (imageFile is XFile) {
                                final f = File(imageFile.path);
                                if (kDebugMode) print('[IMAGE] mobile selected XFile path=${f.path}');
                                setDialogState(() {
                                  selectedImage = f;
                                  selectedImagePath = f.path;
                                });
                              } else if (imageFile is File) {
                                if (kDebugMode) print('[IMAGE] mobile selected File path=${imageFile.path}');
                                setDialogState(() {
                                  selectedImage = imageFile;
                                  selectedImagePath = imageFile.path;
                                });
                              } else {
                                if (kDebugMode) print('[IMAGE] mobile selected unknown type=${imageFile.runtimeType}');
                                setDialogState(() {
                                  selectedImage = imageFile;
                                  selectedImagePath = imageFile?.path ?? selectedImagePath;
                                });
                              }
                            } catch (e) {
                              if (kDebugMode) print('[IMAGE] error handling mobile image: $e');
                            }
                          }
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (selectedImage != null || (selectedImagePath != null && selectedImagePath!.isNotEmpty))
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _buildImagePreview(selectedImage, selectedImagePath),
                                )
                              else
                                Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_circle,
                                    color: Colors.green[700],
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Informasi Utama Section
                    _buildSectionTitle('Informasi Utama'),
                    const SizedBox(height: 16),

                    _buildTextField(namaController, 'Nama Bahan Baku'),
                    const SizedBox(height: 16),

                    // Unit Dropdown
                    _buildDropdown(
                      label: 'Unit',
                      value: selectedUnit,
                      items: ['kg', 'gr', 'dus'],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedUnit = newValue;
                            stokMinimal = getStokMinimalByUnit(newValue);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(grossQtyController, 'Gross Qty', TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(hargaGrossController, 'Harga Per Gross Qty', TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(hargaUnitController, 'Harga Per Unit', TextInputType.number),
                    const SizedBox(height: 30),

                    // Stok Section
                    _buildSectionTitle('Stok'),
                    const SizedBox(height: 16),

                    _buildTextField(stokTersediaController, 'Stok Tersedia', TextInputType.number),
                    const SizedBox(height: 16),

                    // Stok Minimal (Read-only, auto-calculated)
                    _buildReadOnlyField('Stok Minimal', '$stokMinimal $selectedUnit'),
                    const SizedBox(height: 30),

                    // Kadaluarsa dan Penyimpanan Section
                    _buildSectionTitle('Kadaluarsa dan Penyimpanan'),
                    const SizedBox(height: 16),

                    // Tanggal Masuk (Date Picker)
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: tanggalMasuk ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.orange[700]!,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tanggalMasuk = picked;
                            tanggalKadaluarsa = calculateExpiryDate(picked, estimasiUmurController.text);
                          });
                        }
                      },
                      child: IgnorePointer(
                        child: _buildTextField(
                          TextEditingController(
                            text: tanggalMasuk != null
                                ? '${tanggalMasuk!.day.toString().padLeft(2, '0')}/${tanggalMasuk!.month.toString().padLeft(2, '0')}/${tanggalMasuk!.year}'
                                : '',
                          ),
                          'Tanggal Masuk',
                          null,
                          Icons.calendar_today,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Estimasi Umur Simpan
                    _buildTextField(
                      estimasiUmurController,
                      'Estimasi Penyimpanan (hari)',
                      TextInputType.number,
                      null,
                          (value) {
                        setDialogState(() {
                          tanggalKadaluarsa = calculateExpiryDate(tanggalMasuk, value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Kadaluarsa (Auto-calculated, Read-only)
                    _buildReadOnlyField(
                      'Tgl Kadaluarsa',
                      tanggalKadaluarsa != null
                          ? '${tanggalKadaluarsa!.day.toString().padLeft(2, '0')}/${tanggalKadaluarsa!.month.toString().padLeft(2, '0')}/${tanggalKadaluarsa!.year}'
                          : '',
                    ),
                    const SizedBox(height: 16),

                    // Kategori
                    InkWell(
                      onTap: () => _showKategoriDialog(kategoriController),
                      child: IgnorePointer(
                        child: _buildTextField(
                          kategoriController,
                          'Kategori',
                          null,
                          Icons.arrow_drop_down,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(tempatPenyimpananController, 'Tempat Penyimpanan'),
                    const SizedBox(height: 30),

                    // Catatan Section
                    _buildSectionTitle('Catatan Tambahan (Opsional)'),
                    const SizedBox(height: 16),

                    TextField(
                      controller: catatanController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.orange[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.orange[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Simpan Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (namaController.text.isEmpty) {
                            Fluttertoast.showToast(
                              msg: "Nama bahan harus diisi!",
                              backgroundColor: Colors.red,
                            );
                            return;
                          }

                          // Proses upload/generate image URL jika ada gambar yang dipilih
                          String imageUrl = '';

                          if (selectedImage != null) {
                            if (kDebugMode) print('[IMAGE] selectedImage runtimeType=${selectedImage.runtimeType} selectedImagePath=$selectedImagePath');

                            try {
                              Fluttertoast.showToast(
                                msg: "Memproses gambar...",
                                backgroundColor: Colors.blue,
                              );

                              // 1) Try save local asset on mobile
                              if (!kIsWeb) {
                                try {
                                  File? fileToSave;
                                  if (selectedImage is File) {
                                    fileToSave = selectedImage;
                                  } else if (selectedImage is XFile) {
                                    fileToSave = File(selectedImage.path);
                                  }
                                  if (fileToSave != null) {
                                    final localPath = await ImageHelper.saveImageToAssets(
                                      fileToSave,
                                      namaController.text.replaceAll(' ', '_'),
                                    );
                                    if (localPath != null && localPath.isNotEmpty) {
                                      imageUrl = localPath;
                                      if (kDebugMode) print('[IMAGE] saved local path: $imageUrl');
                                    }
                                  }
                                } catch (e) {
                                  if (kDebugMode) print('[IMAGE] saveImageToAssets failed: $e');
                                }
                              }

                              // 2) Try upload to GoCloud (if helper supports File)
                              try {
                                File? fileForUpload;
                                if (selectedImage is File) {
                                  fileForUpload = selectedImage;
                                } else if (selectedImage is XFile) {
                                  fileForUpload = File(selectedImage.path);
                                }
                                if (fileForUpload != null) {
                                  final cloudUrl = await ImageHelper.uploadImageToGoCloud(
                                    imageFile: fileForUpload,
                                    token: token,
                                    project: project,
                                    fileName: namaController.text.replaceAll(' ', '_'),
                                  );
                                  if (cloudUrl != null && cloudUrl.isNotEmpty) {
                                    imageUrl = cloudUrl;
                                    if (kDebugMode) print('[IMAGE] uploaded to cloud: $imageUrl');
                                  }
                                }
                              } catch (e) {
                                if (kDebugMode) print('[IMAGE] uploadImageToGoCloud failed: $e');
                              }

                              // 3) Fallback to base64/data URL (ensures imageUrl is produced)
                              if (imageUrl.isEmpty) {
                                try {
                                  Uint8List bytes = Uint8List(0);
                                  if (selectedImage is File) {
                                    bytes = await selectedImage.readAsBytes();
                                  } else if (selectedImage is XFile) {
                                    bytes = await selectedImage.readAsBytes();
                                  } else if (selectedImage is Uint8List) {
                                    bytes = selectedImage;
                                  }

                                  if (bytes.isNotEmpty) {
                                    final b64 = base64Encode(bytes);
                                    imageUrl = 'data:image/png;base64,$b64';
                                    if (kDebugMode) print('[IMAGE] fallback to data url length=${imageUrl.length}');
                                  } else {
                                    // safe check for selectedImagePath data url
                                    final path = selectedImagePath;
                                    if (path != null && path.startsWith('data:image')) {
                                      imageUrl = path;
                                      if (kDebugMode) print('[IMAGE] used selectedImagePath data url');
                                    }
                                  }
                                } catch (e) {
                                  if (kDebugMode) print('[IMAGE] convert to base64 failed: $e');
                                }
                              }

                              // 4) Extra safety: if still empty, try selectedImagePath if valid
                              if (imageUrl.isEmpty) {
                                final path = selectedImagePath;
                                if (path != null) {
                                  if (path.startsWith('data:image')) {
                                    imageUrl = path;
                                  } else if (!kIsWeb) {
                                    try {
                                      final f = File(path);
                                      if (await f.exists()) imageUrl = path;
                                    } catch (_) {}
                                  }
                                }
                              }
                            } catch (e) {
                              if (kDebugMode) print('[IMAGE] Error memproses gambar: $e');
                            }
                          } else {
                            if (isEdit && bahanBaku!.foto_bahan.isNotEmpty) {
                              imageUrl = bahanBaku.foto_bahan;
                            }
                          }

                          if (kDebugMode) print('[IMAGE] final imageUrl=$imageUrl');

                          Navigator.pop(context);

                          String tanggalMasukStr = tanggalMasuk != null
                              ? '${tanggalMasuk!.year}-${tanggalMasuk!.month.toString().padLeft(2, '0')}-${tanggalMasuk!.day.toString().padLeft(2, '0')}'
                              : '';
                          String tanggalKadaluarsaStr = tanggalKadaluarsa != null
                              ? '${tanggalKadaluarsa!.year}-${tanggalKadaluarsa!.month.toString().padLeft(2, '0')}-${tanggalKadaluarsa!.day.toString().padLeft(2, '0')}'
                              : '';

                          if (isEdit) {
                            await _updateBahanBaku(
                              bahanBaku!.id,
                              namaController.text,
                              selectedUnit,
                              hargaGrossController.text,
                              hargaUnitController.text,
                              stokTersediaController.text,
                              stokMinimal,
                              estimasiUmurController.text,
                              tanggalMasukStr,
                              tanggalKadaluarsaStr,
                              kategoriController.text,
                              tempatPenyimpananController.text,
                              grossQtyController.text,
                              catatanController.text,
                              imageUrl,
                              bahanBaku.nama_bahan,
                            );
                          } else {
                            await _addBahanBaku(
                              namaController.text,
                              selectedUnit,
                              hargaGrossController.text,
                              hargaUnitController.text,
                              stokTersediaController.text,
                              stokMinimal,
                              estimasiUmurController.text,
                              tanggalMasukStr,
                              tanggalKadaluarsaStr,
                              kategoriController.text,
                              tempatPenyimpananController.text,
                              grossQtyController.text,
                              catatanController.text,
                              imageUrl,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Simpan Data Bahan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addBahanBaku(
      String nama,
      String unit,
      String hargaGross,
      String hargaUnit,
      String stokTersedia,
      String stokMinimal,
      String estimasi_penyimpanan,
      String tanggalMasuk,
      String tanggalKadaluarsa,
      String kategori,
      String tempatPenyimpanan,
      String grossQty,
      String catatan,
      String foto_bahan,
      ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) print('=== MULAI INSERT ===');

      final result = await _data_service.insertBahanBaku(
        appid,
        foto_bahan,
        nama,
        unit,
        grossQty,
        hargaGross,
        hargaUnit,
        stokTersedia,
        estimasi_penyimpanan,
        tanggalMasuk,
        tanggalKadaluarsa,
        kategori,
        tempatPenyimpanan,
        catatan,
      );

      if (kDebugMode) print('Result insert: $result');

      await Future.delayed(const Duration(milliseconds: 500));
      await _loadBahanBaku();

      Fluttertoast.showToast(
        msg: "Bahan baku '$nama' berhasil ditambahkan!",
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
      String nama,
      String unit,
      String hargaGross,
      String hargaUnit,
      String stokTersedia,
      String stokMinimal,
      String estimasi_penyimpanan,
      String tanggalMasuk,
      String tanggalKadaluarsa,
      String kategori,
      String tempatPenyimpanan,
      String grossQty,
      String catatan,
      String foto_bahan,
      String namaLama,
      ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print('=== MULAI UPDATE BAHAN BAKU ===');
        print('ID: $id');
        print('Nama Lama: $namaLama');
        print('Nama Baru: $nama');
      }

      if (id.isEmpty || id == '') {
        if (kDebugMode) print('ID kosong, menggunakan updateWhere berdasarkan nama');

        final fields = {
          'nama_bahan': nama,
          'unit': unit,
          'harga_per_gross': hargaGross,
          'harga_per_unit': hargaUnit,
          'stok_tersedia': stokTersedia,
          'stok_minimal': stokMinimal,
          'estimasi_umur': estimasi_penyimpanan,
          'tanggal_masuk': tanggalMasuk,
          'tanggal_kadaluarsa': tanggalKadaluarsa,
          'kategori': kategori,
          'tempat_penyimpanan': tempatPenyimpanan,
          'gross_qty': grossQty,
          'catatan': catatan,
          'foto_bahan': foto_bahan,
        };

        for (var entry in fields.entries) {
          final result = await _data_service.updateWhere(
            'nama_bahan',
            namaLama,
            entry.key,
            entry.value,
            token,
            project,
            'bahan_baku',
            appid,
          );
          if (kDebugMode) print('Update ${entry.key}: $result');
        }
      } else {
        if (kDebugMode) print('Menggunakan updateId');

        final results = await Future.wait([
          _data_service.updateId('nama_bahan', nama, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('unit', unit, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('harga_per_gross', hargaGross, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('harga_per_unit', hargaUnit, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('stok_tersedia', stokTersedia, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('stok_minimal', stokMinimal, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('estimasi_umur', estimasi_penyimpanan, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('tanggal_masuk', tanggalMasuk, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('tanggal_kadaluarsa', tanggalKadaluarsa, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('kategori', kategori, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('tempat_penyimpanan', tempatPenyimpanan, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('gross_qty', grossQty, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('catatan', catatan, token, project, 'bahan_baku', appid, id),
          _data_service.updateId('foto_bahan', foto_bahan, token, project, 'bahan_baku', appid, id),
        ]);

        if (kDebugMode) print('Update results: $results');
      }

      if (kDebugMode) print('✓ Update berhasil di API');

      await _loadBahanBaku();

      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Bahan baku '$nama' berhasil diupdate!",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_SHORT,
      );

      if (kDebugMode) print('=== SELESAI UPDATE ===');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('=== ERROR UPDATE ===');
        print('Error: $e');
        print('StackTrace: $stackTrace');
      }

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
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Bahan Baku?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin menghapus "$nama"? Data yang dihapus tidak dapat dikembalikan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Hapus', style: TextStyle(color: Colors.white)),
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
      if (kDebugMode) {
        print('=== MULAI DELETE BAHAN BAKU ===');
        print('ID yang akan dihapus: $id');
        print('Nama bahan: $nama');
      }

      final result = await _data_service.removeWhere(
        token,
        project,
        'bahan_baku',
        appid,
        'nama_bahan',
        nama,
      );

      if (kDebugMode) print('Result delete dari API: $result');

      if (result == true || result == 'true' || result.toString().contains('"status":"1"')) {
        if (kDebugMode) print('✓ Delete berhasil di database!');

        setState(() {
          _bahanBakuList.removeWhere((item) => item.nama_bahan == nama);
          _filteredList.removeWhere((item) => item.nama_bahan == nama);
        });

        Fluttertoast.showToast(
          msg: "Bahan baku '$nama' berhasil dihapus!",
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT,
        );

        if (kDebugMode) print('✓ Data berhasil dihapus dari tampilan');
      } else {
        if (kDebugMode) print('✗ Delete gagal: $result');
        throw Exception('Delete gagal: $result');
      }

      if (kDebugMode) print('=== SELESAI DELETE ===');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('=== ERROR DELETE ===');
        print('Error: $e');
        print('StackTrace: $stackTrace');
      }

      Fluttertoast.showToast(
        msg: "Gagal menghapus bahan baku: ${e.toString()}",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );

      await _loadBahanBaku();
    }
  }

  void _showDetailBahanBaku(BahanBakuModel bahan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              bahan.nama_bahan,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.orange[300]!, width: 3),
                  ),
                  child: bahan.foto_bahan.isNotEmpty
                      ? _buildImageWidget(bahan.foto_bahan)
                      : const Icon(
                    Icons.inventory_2,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
                // rest unchanged ...
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.orange[700],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, [
        TextInputType? keyboardType,
        IconData? suffixIcon,
        Function(String)? onChanged,
      ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.orange[700]) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: 'Pilih $label',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
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
                  color: Color(0xFF8B5A3C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pilih Kategori',
                  style: TextStyle(
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
                        leading: const Icon(Icons.add, color: Color(0xFF8B5A3C)),
                        title: const Text('Tambah Kategori Baru'),
                        onTap: () {
                          Navigator.pop(context);
                          _showTambahKategoriDialog(kategoriController);
                        },
                      );
                    }
                    return ListTile(
                      title: Text(_kategoriList[index]),
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
              const Text(
                'Tambah Kategori Baru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: newKategoriController,
                decoration: InputDecoration(
                  hintText: 'Nama Kategori',
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
                    backgroundColor: const Color(0xFF8B5A3C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              decoration: InputDecoration(
                hintText: 'Cari bahan baku...',
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
                  borderSide: const BorderSide(color: Color(0xFF8B5A3C), width: 2),
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
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tidak ada data bahan baku', style: TextStyle(color: Colors.grey)),
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
                        color: const Color(0xFF8B5A3C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageWidget(bahan.foto_bahan),
                      ),
                    ),
                    title: Text(
                      bahan.nama_bahan,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Stok: ${bahan.stok_tersedia} ${bahan.unit}'),
                        Text('Kategori: ${bahan.kategori}'),
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
                    onTap: () => _showDetailBahanBaku(bahan),
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
        label: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Helper method untuk menampilkan gambar yang mendukung Web dan Mobile
  Widget _buildImageWidget(String imagePath) {
    if (imagePath.isEmpty) {
      return const Icon(
        Icons.inventory_2,
        color: Color(0xFF8B5A3C),
      );
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.inventory_2,
            color: Color(0xFF8B5A3C),
          );
        },
      );
    } else if (imagePath.startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(imagePath.split(',').last),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.inventory_2,
              color: Color(0xFF8B5A3C),
            );
          },
        );
      } catch (e) {
        return const Icon(
          Icons.inventory_2,
          color: Color(0xFF8B5A3C),
        );
      }
    } else if (!kIsWeb) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.inventory_2,
                color: Color(0xFF8B5A3C),
              );
            },
          );
        } else {
          return const Icon(
            Icons.inventory_2,
            color: Color(0xFF8B5A3C),
          );
        }
      } catch (e) {
        return const Icon(
          Icons.inventory_2,
          color: Color(0xFF8B5A3C),
        );
      }
    } else {
      return const Icon(
        Icons.inventory_2,
        color: Color(0xFF8B5A3C),
      );
    }
  }

  // Method untuk preview gambar saat memilih gambar baru
  Widget _buildImagePreview(dynamic imageObj, String? imagePath) {
    if (imageObj != null) {
      if (imageObj is Uint8List) {
        return Image.memory(
          imageObj,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.inventory_2,
              color: Colors.white,
              size: 50,
            );
          },
        );
      } else if (imageObj is File) {
        return Image.file(
          imageObj,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.inventory_2,
              color: Colors.white,
              size: 50,
            );
          },
        );
      } else if (imageObj is XFile) {
        return Image.file(
          File(imageObj.path),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.inventory_2,
              color: Colors.white,
              size: 50,
            );
          },
        );
      }
    } else if (imagePath != null && imagePath.isNotEmpty) {
      return _buildImageWidget(imagePath);
    }

    return Icon(
      Icons.camera_alt,
      size: 50,
      color: Colors.white.withOpacity(0.8),
    );
  }
}