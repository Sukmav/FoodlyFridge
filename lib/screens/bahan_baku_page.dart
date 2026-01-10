import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../restapi.dart';
import '../config.dart';
import '../model/bahan_baku_model.dart';

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
  List<String> _tempatPenyimpananList = [];

  @override
  void initState() {
    super.initState();
    _loadBahanBaku();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    Set<String> uniqueKategori = {};
    for (var bahan in _bahanBakuList) {
      if (bahan.kategori. isNotEmpty) {
        uniqueKategori.add(bahan.kategori);
      }
    }
    setState(() {
      _kategoriList = uniqueKategori.toList()..sort();
    });
  }

  void _saveKategori(String kategori) {
    if (! _kategoriList.contains(kategori)) {
      setState(() {
        _kategoriList.add(kategori);
        _kategoriList.sort();
      });
    }
  }

  Future<void> _loadTempatPenyimpanan() async {
    Set<String> uniqueTempat = {};
    for (var bahan in _bahanBakuList) {
      if (bahan.tempat_penyimpanan.isNotEmpty) {
        uniqueTempat.add(bahan. tempat_penyimpanan);
      }
    }
    setState(() {
      _tempatPenyimpananList = uniqueTempat.toList()..sort();
    });
  }

  void _saveTempatPenyimpanan(String tempat) {
    if (!_tempatPenyimpananList.contains(tempat)) {
      setState(() {
        _tempatPenyimpananList.add(tempat);
        _tempatPenyimpananList.sort();
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

      print('Response:  $response');

      if (response == '[]' || response. isEmpty || response == 'null') {
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

      final newList = dataList.map((json) => BahanBakuModel. fromJson(json)).toList();

      setState(() {
        _bahanBakuList = newList;
        _filteredList = List.from(_bahanBakuList);
        _isLoading = false;
      });

      print('Data berhasil dimuat:  ${_bahanBakuList.length} items');

      await _loadKategori();
      await _loadTempatPenyimpanan();

    } catch (e, stackTrace) {
      print('Error:  $e');
      print('StackTrace: $stackTrace');

      setState(() {
        _bahanBakuList = [];
        _filteredList = [];
        _isLoading = false;
      });

      Fluttertoast. showToast(
        msg:  "Gagal memuat data: ${e.toString()}",
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
            bahan. kategori.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showAddEditDialog({BahanBakuModel?  bahanBaku}) {
    final bool isEdit = bahanBaku != null;

    final TextEditingController namaController = TextEditingController(text: bahanBaku?.nama_bahan ??  '');
    String selectedUnit = bahanBaku?.unit ??  'kg';

    Map<String, String> parseValueWithUnit(String?  value) {
      if (value == null || value.isEmpty) return {'value': '', 'unit': 'kg'};

      final parts = value.trim().split(' ');
      if (parts.length >= 2) {
        return {
          'value': parts[0],
          'unit': parts[1],
        };
      }
      return {'value': value, 'unit': 'kg'};
    }

    final grossQtyParsed = parseValueWithUnit(bahanBaku?.gross_qty);
    final stokTersediaParsed = parseValueWithUnit(bahanBaku?.stok_tersedia);
    final stokMinimalParsed = parseValueWithUnit(bahanBaku?.stok_minimal);

    String selectedSatuanPembelian = grossQtyParsed['unit']!;
    String selectedSatuanStokTersedia = stokTersediaParsed['unit']!;
    String selectedSatuanStokMinimal = stokMinimalParsed['unit']!;

    final TextEditingController hargaGrossController = TextEditingController(text: bahanBaku?.harga_per_gross ??  '');
    final TextEditingController hargaUnitController = TextEditingController(text: bahanBaku?.harga_per_unit ?? '');
    final TextEditingController stokTersediaController = TextEditingController(text: stokTersediaParsed['value']);
    final TextEditingController stokMinimalController = TextEditingController(text: stokMinimalParsed['value']);
    final TextEditingController estimasiUmurController = TextEditingController(text: bahanBaku?.estimasi_umur ?? '');
    final TextEditingController grossQtyController = TextEditingController(text: grossQtyParsed['value']);
    DateTime? tanggalMasuk = bahanBaku?.tanggal_masuk != null && bahanBaku! .tanggal_masuk. isNotEmpty
        ? DateTime. tryParse(bahanBaku. tanggal_masuk)
        : null;
    DateTime? tanggalKadaluarsa = bahanBaku?.tanggal_kadaluarsa != null && bahanBaku!.tanggal_kadaluarsa.isNotEmpty
        ? DateTime.tryParse(bahanBaku.tanggal_kadaluarsa)
        : null;
    final TextEditingController kategoriController = TextEditingController(text: bahanBaku?.kategori ?? '');
    final TextEditingController tempatPenyimpananController = TextEditingController(text: bahanBaku?.tempat_penyimpanan ?? '');
    final TextEditingController catatanController = TextEditingController(text: bahanBaku?. catatan ?? '');

    // Variable untuk menyimpan gambar yang dipilih
    File? selectedImage;
    String? fotoBase64 = bahanBaku?.foto_bahan;

    DateTime? calculateExpiryDate(DateTime? startDate, String estimasi) {
      if (startDate == null || estimasi. isEmpty) return null;
      try {
        int days = int.parse(estimasi);
        return startDate.add(Duration(days: days));
      } catch (e) {
        return null;
      }
    }

    // Function untuk pick image dari camera
    Future<void> pickImageFromCamera(StateSetter setDialogState) async {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          final imageFile = File(pickedFile.path);
          final bytes = await imageFile.readAsBytes();

          setDialogState(() {
            selectedImage = imageFile;
            fotoBase64 = base64Encode(bytes);
          });

          Fluttertoast.showToast(
            msg: "Foto berhasil diambil",
            backgroundColor: Colors.green,
          );
        }
      } catch (e) {
        print('Error mengambil foto: $e');
        Fluttertoast.showToast(
          msg: "Gagal mengambil foto:  $e",
          backgroundColor: Colors.red,
        );
      }
    }

    // Function untuk pick image dari gallery
    Future<void> pickImageFromGallery(StateSetter setDialogState) async {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          final imageFile = File(pickedFile.path);
          final bytes = await imageFile.readAsBytes();

          setDialogState(() {
            selectedImage = imageFile;
            fotoBase64 = base64Encode(bytes);
          });

          Fluttertoast.showToast(
            msg: "Foto berhasil dipilih",
            backgroundColor: Colors.green,
          );
        }
      } catch (e) {
        print('Error memilih gambar: $e');
        Fluttertoast.showToast(
          msg: "Gagal memilih gambar:  $e",
          backgroundColor: Colors.red,
        );
      }
    }

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
                foregroundColor:  Colors.white,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Upload Gambar
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green[700]!, width: 3),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (selectedImage != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image. file(
                                      selectedImage!,
                                      width:  120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else if (fotoBase64 != null && fotoBase64! .isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius. circular(16),
                                    child: _buildImageFromBase64(fotoBase64! ),
                                  )
                                else
                                  Icon(
                                    Icons. camera_alt,
                                    size: 50,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                if (selectedImage == null && (fotoBase64 == null || fotoBase64!.isEmpty))
                                  Positioned(
                                    bottom:  10,
                                    right: 10,
                                    child:  Container(
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
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton. icon(
                                onPressed:  () => pickImageFromCamera(setDialogState),
                                icon: const Icon(Icons.camera_alt, size: 20),
                                label: const Text('Kamera'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => pickImageFromGallery(setDialogState),
                                icon: const Icon(Icons.photo_library, size: 20),
                                label: const Text('Galeri'),
                                style: ElevatedButton. styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height:  30),

                    _buildSectionTitle('Informasi Utama'),
                    const SizedBox(height: 16),

                    _buildTextField(namaController, 'Nama Bahan Baku'),
                    const SizedBox(height: 16),

                    _buildDropdown(
                      label: 'Unit',
                      value: selectedUnit,
                      items: ['kg', 'gr', 'dus'],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedUnit = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height:  16),

                    _buildTextFieldWithUnit(
                      controller: grossQtyController,
                      label: 'Satuan Pembelian',
                      selectedUnit: selectedSatuanPembelian,
                      onUnitChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedSatuanPembelian = newValue;
                          });
                        }
                      },
                      setState: setDialogState,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(hargaGrossController, 'Harga Per Satuan', TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(hargaUnitController, 'Harga Per Unit', TextInputType.number),
                    const SizedBox(height:  30),

                    _buildSectionTitle('Stok'),
                    const SizedBox(height: 16),

                    _buildTextFieldWithUnit(
                      controller: stokTersediaController,
                      label: 'Stok Tersedia',
                      selectedUnit: selectedSatuanStokTersedia,
                      onUnitChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedSatuanStokTersedia = newValue;
                          });
                        }
                      },
                      setState: setDialogState,
                    ),
                    const SizedBox(height: 16),

                    _buildTextFieldWithUnit(
                      controller:  stokMinimalController,
                      label: 'Stok Minimal',
                      selectedUnit: selectedSatuanStokMinimal,
                      onUnitChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedSatuanStokMinimal = newValue;
                          });
                        }
                      },
                      setState: setDialogState,
                    ),
                    const SizedBox(height: 30),

                    _buildSectionTitle('Kadaluarsa dan Penyimpanan'),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: tanggalMasuk ?? DateTime. now(),
                          firstDate:  DateTime(2020),
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
                                ? '${tanggalMasuk! .day.toString().padLeft(2, '0')}/${tanggalMasuk!.month.toString().padLeft(2, '0')}/${tanggalMasuk!.year}'
                                : '',
                          ),
                          'Tanggal Masuk',
                          null,
                          Icons.calendar_today,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    _buildReadOnlyField(
                      'Tgl Kadaluarsa',
                      tanggalKadaluarsa != null
                          ? '${tanggalKadaluarsa!.day.toString().padLeft(2, '0')}/${tanggalKadaluarsa!.month.toString().padLeft(2, '0')}/${tanggalKadaluarsa!.year}'
                          : '',
                    ),
                    const SizedBox(height:  16),

                    InkWell(
                      onTap: () => _showKategoriDialog(kategoriController),
                      child:  IgnorePointer(
                        child: _buildTextField(
                          kategoriController,
                          'Kategori',
                          null,
                          Icons.arrow_drop_down,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () => _showTempatPenyimpananDialog(tempatPenyimpananController),
                      child: IgnorePointer(
                        child: _buildTextField(
                          tempatPenyimpananController,
                          'Tempat Penyimpanan',
                          null,
                          Icons.arrow_drop_down,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildSectionTitle('Catatan Tambahan (Opsional)'),
                    const SizedBox(height: 16),

                    TextField(
                      controller: catatanController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan.. .',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.orange[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:  BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.orange[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius. circular(12),
                          borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width:  double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (namaController.text.isEmpty) {
                            Fluttertoast.showToast(
                              msg: "Nama bahan harus diisi! ",
                              backgroundColor: Colors. red,
                            );
                            return;
                          }

                          Navigator.pop(context);

                          String tanggalMasukStr = tanggalMasuk != null
                              ? '${tanggalMasuk!.year}-${tanggalMasuk!.month.toString().padLeft(2, '0')}-${tanggalMasuk!. day.toString().padLeft(2, '0')}'
                              : '';
                          String tanggalKadaluarsaStr = tanggalKadaluarsa != null
                              ? '${tanggalKadaluarsa!.year}-${tanggalKadaluarsa!.month.toString().padLeft(2, '0')}-${tanggalKadaluarsa!.day.toString().padLeft(2, '0')}'
                              :  '';

                          String grossQtyWithUnit = '${grossQtyController.text} $selectedSatuanPembelian';
                          String stokTersediaWithUnit = '${stokTersediaController.text} $selectedSatuanStokTersedia';
                          String stokMinimalWithUnit = '${stokMinimalController.text} $selectedSatuanStokMinimal';

                          if (isEdit) {
                            await _updateBahanBaku(
                              bahanBaku! .id,
                              namaController. text,
                              selectedUnit,
                              hargaGrossController.text,
                              hargaUnitController.text,
                              stokTersediaWithUnit,
                              stokMinimalWithUnit,
                              estimasiUmurController.text,
                              tanggalMasukStr,
                              tanggalKadaluarsaStr,
                              kategoriController.text,
                              tempatPenyimpananController. text,
                              grossQtyWithUnit,
                              catatanController.text,
                              fotoBase64 ??  '',
                              bahanBaku. nama_bahan,
                            );
                          } else {
                            await _addBahanBaku(
                              namaController.text,
                              selectedUnit,
                              hargaGrossController.text,
                              hargaUnitController.text,
                              stokTersediaWithUnit,
                              stokMinimalWithUnit,
                              estimasiUmurController.text,
                              tanggalMasukStr,
                              tanggalKadaluarsaStr,
                              kategoriController.text,
                              tempatPenyimpananController.text,
                              grossQtyWithUnit,
                              catatanController.text,
                              fotoBase64 ?? '',
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
            suffixIcon: suffixIcon != null ?  Icon(suffixIcon, color: Colors.orange[700]) : null,
            filled: true,
            fillColor:  Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:  BorderSide(color: Colors.orange[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:  BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical:  14),
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
            fontWeight: FontWeight. w500,
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
              borderSide: BorderSide(color: Colors.orange[300]! ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[300]! ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
            ),
            contentPadding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildTextFieldWithUnit({
    required TextEditingController controller,
    required String label,
    required String selectedUnit,
    required Function(String?) onUnitChanged,
    required StateSetter setState,
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
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Jumlah',
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
                    borderRadius:  BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:  BorderSide(color: Colors. orange[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets. symmetric(horizontal: 12, vertical: 14),
                ),
                items: ['kg', 'gr', 'dus', 'liter', 'pcs'].map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onUnitChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showKategoriDialog(TextEditingController kategoriController) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius:  BorderRadius.circular(12),
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
                    topRight:  Radius.circular(12),
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
                child: ListView. builder(
                  shrinkWrap: true,
                  itemCount: _kategoriList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _kategoriList.length) {
                      return ListTile(
                        leading:  const Icon(Icons.add, color: Color(0xFF8B5A3C)),
                        title: const Text('Tambah Kategori Baru'),
                        onTap: () {
                          Navigator.pop(context);
                          _showTambahKategoriDialog(kategoriController);
                        },
                      );
                    }
                    return ListTile(
                      title: Text(_kategoriList[index]),
                      onTap:  () {
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
      context:  context,
      builder: (context) => Dialog(
        shape:  RoundedRectangleBorder(
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
                decoration:  InputDecoration(
                  hintText: 'Nama Kategori',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius. circular(8),
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

  void _showTempatPenyimpananDialog(TextEditingController tempatPenyimpananController) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius:  BorderRadius.circular(12),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width:  double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5A3C),
                  borderRadius:  BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight:  Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pilih Tempat Penyimpanan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap:  true,
                  itemCount:  _tempatPenyimpananList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _tempatPenyimpananList.length) {
                      return ListTile(
                        leading: const Icon(Icons.add, color: Color(0xFF8B5A3C)),
                        title: const Text('Tambah Tempat Penyimpanan Baru'),
                        onTap: () {
                          Navigator.pop(context);
                          _showTambahTempatPenyimpananDialog(tempatPenyimpananController);
                        },
                      );
                    }
                    return ListTile(
                      title:  Text(_tempatPenyimpananList[index]),
                      onTap: () {
                        tempatPenyimpananController. text = _tempatPenyimpananList[index];
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

  void _showTambahTempatPenyimpananDialog(TextEditingController tempatPenyimpananController) {
    final TextEditingController newTempatController = TextEditingController();

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
                'Tambah Tempat Penyimpanan Baru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:  FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: newTempatController,
                decoration:  InputDecoration(
                  hintText: 'Nama Tempat Penyimpanan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width:  double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (newTempatController.text.isNotEmpty) {
                      _saveTempatPenyimpanan(newTempatController.text);
                      tempatPenyimpananController.text = newTempatController.text;
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton. styleFrom(
                    backgroundColor:  const Color(0xFF8B5A3C),
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
      print('=== MULAI INSERT ===');

      final result = await _dataService.insertBahanBaku(
        appid,
        foto_bahan,
        nama,
        unit,
        grossQty,
        hargaGross,
        hargaUnit,
        stokTersedia,
        stokMinimal,
        estimasi_penyimpanan,
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
        msg: "Bahan baku '$nama' berhasil ditambahkan! ",
        backgroundColor: Colors.green,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: "Gagal menambahkan:  ${e.toString()}",
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
      print('=== MULAI UPDATE BAHAN BAKU ===');

      if (id.isEmpty || id == '') {
        print('ID kosong, menggunakan updateWhere berdasarkan nama');

        final fields = {
          'nama_bahan': nama,
          'unit': unit,
          'harga_per_gross': hargaGross,
          'harga_per_unit': hargaUnit,
          'stok_tersedia': stokTersedia,
          'stok_minimal': stokMinimal,
          'estimasi_umur':  estimasi_penyimpanan,
          'tanggal_masuk': tanggalMasuk,
          'tanggal_kadaluarsa': tanggalKadaluarsa,
          'kategori': kategori,
          'tempat_penyimpanan': tempatPenyimpanan,
          'gross_qty': grossQty,
          'catatan': catatan,
          'foto_bahan':  foto_bahan,
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

        await Future.wait([
          _dataService.updateId('nama_bahan', nama, token, project, 'bahan_baku', appid, id),
          _dataService. updateId('unit', unit, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('harga_per_gross', hargaGross, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('harga_per_unit', hargaUnit, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('stok_tersedia', stokTersedia, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('stok_minimal', stokMinimal, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('estimasi_umur', estimasi_penyimpanan, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('tanggal_masuk', tanggalMasuk, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('tanggal_kadaluarsa', tanggalKadaluarsa, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('kategori', kategori, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('tempat_penyimpanan', tempatPenyimpanan, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('gross_qty', grossQty, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('catatan', catatan, token, project, 'bahan_baku', appid, id),
          _dataService.updateId('foto_bahan', foto_bahan, token, project, 'bahan_baku', appid, id),
        ]);
      }

      await _loadBahanBaku();

      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Bahan baku '$nama' berhasil diupdate!",
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

      Fluttertoast. showToast(
        msg:  "Gagal mengupdate: ${e.toString()}",
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
                  color:  Colors.red. withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height:  16),
              const Text(
                'Hapus Bahan Baku? ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin menghapus "$nama"?  Data yang dihapus tidak dapat dikembalikan.',
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
                        backgroundColor: Colors. red,
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
      print('=== MULAI DELETE BAHAN BAKU ===');

      final result = await _dataService.removeWhere(
        token,
        project,
        'bahan_baku',
        appid,
        'nama_bahan',
        nama,
      );

      print('Result delete dari API: $result');

      if (result == true || result == 'true' || result. toString().contains('"status":"1"')) {
        print('✓ Delete berhasil di database! ');

        setState(() {
          _bahanBakuList.removeWhere((item) => item.nama_bahan == nama);
          _filteredList. removeWhere((item) => item.nama_bahan == nama);
        });

        Fluttertoast.showToast(
          msg: "Bahan baku '$nama' berhasil dihapus!",
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT,
        );
      } else {
        throw Exception('Delete gagal:  $result');
      }
    } catch (e, stackTrace) {
      print('=== ERROR DELETE ===');
      print('Error: $e');
      print('StackTrace:  $stackTrace');

      Fluttertoast.showToast(
        msg: "Gagal menghapus bahan baku: ${e.toString()}",
        backgroundColor: Colors. red,
        toastLength:  Toast.LENGTH_LONG,
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
            leading:  IconButton(
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
                    color:  Colors.grey[200],
                    border: Border.all(color: Colors.orange[300]!, width: 3),
                  ),
                  child: bahan.foto_bahan. isNotEmpty
                      ? _buildImageWidget(bahan.foto_bahan)
                      : const Icon(
                    Icons.inventory_2,
                    size: 80,
                    color: Colors. grey,
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.orange[700]!,
                                width:  3,
                              ),
                            ),
                          ),
                          child: Text(
                            'Detail',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Text(
                            'Riwayat',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize:  16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection(
                        'Informasi Pembelian',
                        Colors.orange[700]!,
                        [
                          _buildDetailRow('Satuan Pembelian', '${bahan.gross_qty}', Colors.green[700]!),
                          _buildDetailRow('Harga per Satuan', 'Rp ${bahan. harga_per_gross}', Colors.green[700]!),
                          _buildDetailRow('Jumlah Pernah Beli', '-', Colors.green[700]! ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildDetailSection(
                        'Penggunaan untuk Menu',
                        Colors.orange[700]!,
                        [
                          _buildDetailRow('Unit Dasar', bahan.unit, Colors.green[700]!),
                          _buildDetailRow('Harga per unit', 'Rp${bahan.harga_per_unit}', Colors.green[700]!),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildDetailSection(
                        'Stok',
                        Colors.red[700]!,
                        [
                          _buildDetailRow('Stok tersedia', '${bahan.stok_tersedia}', Colors. green[700]!),
                          _buildDetailRow('Stok Minimal', '${bahan.stok_minimal}', Colors.green[700]!),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildDetailSection(
                        'Kadaluarsa dan Penyimpanan',
                        Colors.red[700]!,
                        [
                          _buildDetailRow('Estimasi umur Simpan', '${bahan. estimasi_umur} hari', Colors.green[700]!),
                          _buildDetailRow('Tgl Kedatangan', _formatDate(bahan.tanggal_masuk), Colors.green[700]!),
                          _buildDetailRow('Tgl Kadaluarsa', _formatDate(bahan.tanggal_kadaluarsa), Colors.green[700]!),
                          _buildDetailRow('Kategori', bahan.kategori, Colors.green[700]!),
                          _buildDetailRow('Penyimpanan', bahan.tempat_penyimpanan, Colors.green[700]!),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Catatan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double. infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange[300]! ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          bahan.catatan. isEmpty ? 'Tidak ada catatan' : bahan.catatan,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      SizedBox(
                        width:  double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator. pop(context);
                            _showAddEditDialog(bahanBaku: bahan);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Ubah',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, Color titleColor, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight. bold,
            color: titleColor,
          ),
        ),
        const Divider(thickness: 1),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:  [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date. day. toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _filterBahanBaku,
                decoration: InputDecoration(
                  hintText: 'Cari bahan baku...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius. circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:  BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius. circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8B5A3C), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            // List content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredList.isEmpty
                  ?  const Center(
                child:  Column(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Tidak ada data bahan baku', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  :  ListView.builder(
                itemCount: _filteredList.length,
                padding: const EdgeInsets.all(16),
                itemBuilder:  (context, index) {
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
                        decoration:  BoxDecoration(
                          color: const Color(0xFF8B5A3C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:  _buildImageWidget(bahan.foto_bahan),
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
                          Text('Stok: ${bahan.stok_tersedia}'),
                          Text('Kategori: ${bahan.kategori}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize. min,
                        children:  [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAddEditDialog(bahanBaku: bahan),
                          ),
                          IconButton(
                            icon:  const Icon(Icons.delete, color: Colors.red),
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
      ),
      floatingActionButton: FloatingActionButton. extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Helper method untuk menampilkan gambar yang mendukung Web dan Mobile
  Widget _buildImageWidget(String imagePath) {
    // Jika string kosong, tampilkan icon default
    if (imagePath.isEmpty) {
      return const Icon(
        Icons.inventory_2,
        color: Color(0xFF8B5A3C),
      );
    }

    // Jika URL (dimulai dengan http)
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
    }

    // Jika base64 (panjang string > 100 dan tidak dimulai dengan http)
    if (imagePath.length > 100 && ! imagePath.startsWith('http')) {
      try {
        // Handle base64 dengan atau tanpa prefix
        final base64String = imagePath.contains(',')
            ? imagePath.split(',').last
            : imagePath;

        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.inventory_2,
              color: Color(0xFF8B5A3C),
            );
          },
        );
      } catch (e) {
        print('Error decoding base64: $e');
        return const Icon(
          Icons.inventory_2,
          color: Color(0xFF8B5A3C),
        );
      }
    }

    // Jika path lokal (hanya untuk mobile)
    if (! kIsWeb) {
      try {
        return Image.file(
          File(imagePath),
          fit: BoxFit. cover,
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
    }

    // Default:  tampilkan icon
    return const Icon(
      Icons.inventory_2,
      color: Color(0xFF8B5A3C),
    );
  }

  // Method untuk menampilkan gambar dari base64 (untuk preview di dialog)
  Widget _buildImageFromBase64(String base64String) {
    try {
      // Handle base64 dengan atau tanpa prefix
      final cleanBase64 = base64String. contains(',')
          ? base64String.split(',').last
          : base64String;

      return Image.memory(
        base64Decode(cleanBase64),
        width: 120,
        height: 120,
        fit: BoxFit. cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading base64 image: $error');
          return Icon(
            Icons.camera_alt,
            size: 50,
            color: Colors.white. withOpacity(0.8),
          );
        },
      );
    } catch (e) {
      print('Error decoding base64 in preview: $e');
      return Icon(
        Icons.camera_alt,
        size: 50,
        color: Colors.white. withOpacity(0.8),
      );
    }
  }
}