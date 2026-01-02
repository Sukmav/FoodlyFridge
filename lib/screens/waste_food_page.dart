import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../model/waste_food.dart';
import '../model/bahan_baku_model.dart';
import '../helpers/bahan_baku_service.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class WasteFoodPage extends StatefulWidget {
  final String userId;
  final String userName; // Nama user yang sedang login

  const WasteFoodPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<WasteFoodPage> createState() => _WasteFoodPageState();
}

class _WasteFoodPageState extends State<WasteFoodPage> {
  List<WasteFoodModel> _wasteList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWasteFood();
  }

  Future<void> _loadWasteFood() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$fileUri/select/'),
        body: {
          'token': token,
          'project': project,
          'collection': 'waste_food',
          'appid': appid,
          'user_id': widget.userId,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _wasteList = data.map((item) => WasteFoodModel.fromJson(item)).toList();
          });
        }
      }
    } catch (e) {
      print('Error loading waste food: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToAddWasteFood() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahWasteFoodPage(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );

    if (result == true) {
      _loadWasteFood();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wasteList.isEmpty
          ? _buildEmptyState()
          : _buildWasteList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddWasteFood,
        backgroundColor: const Color(0xFF7A9B3B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 120, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Data Waste Food',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan data untuk memulai',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _wasteList.length,
      itemBuilder: (context, index) {
        final waste = _wasteList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            leading: waste.foto.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(waste.foto),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            )
                : Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.image, color: Colors.grey[600]),
            ),
            title: Text(
              waste.nama_bahan,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${waste.jenis_waste} - ${waste.jumlah_terbuang}'),
                Text(waste.tanggal),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== TAMBAH WASTE FOOD PAGE ====================
class TambahWasteFoodPage extends StatefulWidget {
  final String userId;
  final String userName;

  const TambahWasteFoodPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<TambahWasteFoodPage> createState() => _TambahWasteFoodPageState();
}

class _TambahWasteFoodPageState extends State<TambahWasteFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final BahanBakuService _bahanBakuService = BahanBakuService();

  // Controllers
  final TextEditingController _jumlahTerbuangController = TextEditingController();
  final TextEditingController _totalKerugianController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  BahanBakuModel? _selectedBahanBaku;
  String? _selectedJenisWaste;
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  String? _fotoBase64;
  bool _isLoading = false;

  List<BahanBakuModel> _bahanBakuList = [];

  final List<String> _jenisWasteOptions = [
    'Expired',
    'Rusak',
    'Busuk',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadBahanBaku();
    _totalKerugianController.text = 'otomatis';
  }

  @override
  void dispose() {
    _jumlahTerbuangController.dispose();
    _totalKerugianController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadBahanBaku() async {
    try {
      final bahanBakuList = await _bahanBakuService.getBahanBakuByUserId(widget.userId);
      setState(() {
        _bahanBakuList = bahanBakuList;
      });
    } catch (e) {
      print('Error loading bahan baku: $e');
    }
  }

  void _onBahanBakuSelected(BahanBakuModel? bahanBaku) {
    setState(() {
      _selectedBahanBaku = bahanBaku;
      // Kode bahan dihilangkan sesuai permintaan — hanya set selected bahan dan hitung total
      if (bahanBaku != null) {
        _calculateTotalKerugian();
      } else {
        _totalKerugianController.text = 'otomatis';
      }
    });
  }

  void _calculateTotalKerugian() {
    if (_selectedBahanBaku != null && _jumlahTerbuangController.text.isNotEmpty) {
      try {
        final jumlahTerbuang = double.parse(_jumlahTerbuangController.text);
        final hargaSatuan = double.parse(_selectedBahanBaku!.harga_per_unit);
        final totalKerugian = jumlahTerbuang * hargaSatuan;

        _totalKerugianController.text = 'Rp ${NumberFormat('#,###', 'id_ID').format(totalKerugian)}';
      } catch (e) {
        _totalKerugianController.text = 'otomatis';
      }
    } else {
      _totalKerugianController.text = 'otomatis';
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        final bytes = await _selectedImage!.readAsBytes();
        _fotoBase64 = base64Encode(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        final bytes = await _selectedImage!.readAsBytes();
        _fotoBase64 = base64Encode(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7A9B3B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _simpanWasteFood() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBahanBaku == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bahan baku terlebih dahulu')),
      );
      return;
    }

    if (_selectedJenisWaste == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis waste terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$fileUri/insert/'),
        body: {
          'token': token,
          'project': project,
          'collection': 'waste_food',
          'appid': appid,
          'user_id': widget.userId,
          'nama_bahan': _selectedBahanBaku!.nama_bahan,
          'jenis_waste': _selectedJenisWaste!,
          'jumlah_terbuang': '${_jumlahTerbuangController.text} ${_selectedBahanBaku!.unit}',
          'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'catatan': _catatanController.text,
          'foto': _fotoBase64 ?? '',
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data waste food berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Data',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Section: Detail Waste
            Text(
              'Detail Waste',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD4A373),
              ),
            ),
            const Divider(color: Color(0xFFD4A373), thickness: 1),
            const SizedBox(height: 16),

            // Nama Bahan Baku - Dropdown
            Text(
              'Nama Bahan Baku',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4A373)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BahanBakuModel>(
                  value: _selectedBahanBaku,
                  isExpanded: true,
                  hint: Text(
                    'Pilih Bahan Baku',
                    style: GoogleFonts.poppins(color: const Color(0xFFD4A373)),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4A373)),
                  style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
                  items: _bahanBakuList.map((BahanBakuModel bahanBaku) {
                    return DropdownMenuItem<BahanBakuModel>(
                      value: bahanBaku,
                      child: Text(bahanBaku.nama_bahan),
                    );
                  }).toList(),
                  onChanged: _onBahanBakuSelected,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Jenis Waste - Dropdown
            Text(
              'Jenis Waste',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4A373)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedJenisWaste,
                  isExpanded: true,
                  hint: Text(
                    'Pilih Jenis Waste',
                    style: GoogleFonts.poppins(color: const Color(0xFFD4A373)),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4A373)),
                  style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
                  items: _jenisWasteOptions.map((String jenis) {
                    return DropdownMenuItem<String>(
                      value: jenis,
                      child: Text(jenis),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedJenisWaste = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Jumlah Terbuang
            Text(
              'Jumlah Terbuang',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _jumlahTerbuangController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Masukkan jumlah',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4A373)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4A373)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4A373), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.poppins(),
              onChanged: (value) => _calculateTotalKerugian(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah terbuang harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Total Kerugian (Otomatis)
            Text(
              'Total Kerugian',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _totalKerugianController,
              enabled: false,
              decoration: InputDecoration(
                hintText: 'otomatis',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4A373)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4A373)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Tanggal
            Text(
              'Tanggal',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD4A373)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: GoogleFonts.poppins(color: Colors.black87),
                    ),
                    const Icon(Icons.calendar_today, color: Color(0xFFD4A373), size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section: Catatan & Foto Bukti
            Text(
              'Catatan & Foto Bukti',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD4A373),
              ),
            ),
            const Divider(color: Color(0xFFD4A373), thickness: 1),
            const SizedBox(height: 16),

            // Catatan
            Text(
              'Catatan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _catatanController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tambah Catatan',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4A373)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4A373)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4A373), width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),

            // Foto Bukti & Buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto Preview
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD4A373), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                      : Center(
                    child: Text(
                      'Foto Bukti',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFD4A373),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Buttons
                Column(
                  children: [
                    SizedBox(
                      width: 120,
                      child: OutlinedButton(
                        onPressed: _pickImageFromCamera,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7A9B3B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Kamera',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF7A9B3B),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 120,
                      child: OutlinedButton(
                        onPressed: _pickImageFromGallery,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7A9B3B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Galeri',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF7A9B3B),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Diinputkan
            Text(
              'Diinputkan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD4A373),
              ),
            ),
            const Divider(color: Color(0xFFD4A373), thickness: 1),
            const SizedBox(height: 16),

            // Oleh (Otomatis terisi nama user)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Oleh',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7A9B3B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanWasteFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A9B3B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Simpan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}