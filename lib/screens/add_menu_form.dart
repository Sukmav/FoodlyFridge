// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'dart:convert';
// import 'dart:io';
// import '../restapi.dart';
// import '../config.dart';
// import '../model/bahan_baku_model.dart';
// import '../helpers/image_helper.dart';
//
// class AddMenuForm extends StatefulWidget {
//   const AddMenuForm({super.key, required this.onMenuAdded});
//
//   final VoidCallback onMenuAdded;
//
//   @override
//   State<AddMenuForm> createState() => _AddMenuFormState();
// }
//
// class _AddMenuFormState extends State<AddMenuForm> {
//   final DataService _dataService = DataService();
//
//   final _kodeMenuController = TextEditingController();
//   final _namaMenuController = TextEditingController();
//   final _hargaJualController = TextEditingController();
//   final _barcodeController = TextEditingController();
//   final _catatanController = TextEditingController();
//
//   String? _selectedKategori;
//   File? _selectedImage;
//   String? _selectedImagePath;
//
//   List<BahanBakuModel> _availableBahanBaku = [];
//   bool _isLoadingBahanBaku = false;
//
//   // List bahan baku yang dipilih untuk menu
//   List<Map<String, dynamic>> _selectedBahanBakuList = [];
//
//   double _totalRecipeCost = 0.0;
//   double _foodCostPercentage = 0.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadBahanBaku();
//     _hargaJualController.addListener(_calculateFoodCost);
//   }
//
//   @override
//   void dispose() {
//     _kodeMenuController.dispose();
//     _namaMenuController.dispose();
//     _hargaJualController.dispose();
//     _barcodeController.dispose();
//     _catatanController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadBahanBaku() async {
//     setState(() {
//       _isLoadingBahanBaku = true;
//     });
//
//     try {
//       print('=== LOADING BAHAN BAKU ===');
//       final response = await _dataService.selectAll(
//         token,
//         project,
//         'bahan_baku',
//         appid,
//       );
//
//       if (response == '[]' || response.isEmpty || response == 'null') {
//         setState(() {
//           _availableBahanBaku = [];
//           _isLoadingBahanBaku = false;
//         });
//         return;
//       }
//
//       final dynamic decodedData = json.decode(response);
//       List<dynamic> dataList;
//
//       if (decodedData is Map && decodedData.containsKey('data')) {
//         dataList = decodedData['data'] as List<dynamic>;
//       } else if (decodedData is List) {
//         dataList = decodedData;
//       } else {
//         dataList = [];
//       }
//
//       final newList = dataList.map((json) => BahanBakuModel.fromJson(json)).toList();
//
//       setState(() {
//         _availableBahanBaku = newList;
//         _isLoadingBahanBaku = false;
//       });
//
//       print('Bahan baku loaded: ${_availableBahanBaku.length} items');
//
//     } catch (e, stackTrace) {
//       print('Error loading bahan baku: $e');
//       print('StackTrace: $stackTrace');
//
//       setState(() {
//         _availableBahanBaku = [];
//         _isLoadingBahanBaku = false;
//       });
//     }
//   }
//
//   void _addBahanBaku() {
//     setState(() {
//       _selectedBahanBakuList.add({
//         'bahan': null,
//         'qty': TextEditingController(),
//         'satuan': '',
//         'cost': 0.0,
//       });
//     });
//   }
//
//   void _removeBahanBaku(int index) {
//     setState(() {
//       _selectedBahanBakuList[index]['qty'].dispose();
//       _selectedBahanBakuList.removeAt(index);
//       _calculateTotalRecipeCost();
//     });
//   }
//
//   void _calculateTotalRecipeCost() {
//     double total = 0.0;
//     for (var item in _selectedBahanBakuList) {
//       if (item['bahan'] != null && item['qty'].text.isNotEmpty) {
//         final BahanBakuModel bahan = item['bahan'];
//         final qty = double.tryParse(item['qty'].text) ?? 0.0;
//         final hargaUnit = double.tryParse(bahan.harga_unit) ?? 0.0;
//         final cost = qty * hargaUnit;
//         item['cost'] = cost;
//         total += cost;
//       }
//     }
//
//     setState(() {
//       _totalRecipeCost = total;
//       _calculateFoodCost();
//     });
//   }
//
//   void _calculateFoodCost() {
//     if (_hargaJualController.text.isNotEmpty && _totalRecipeCost > 0) {
//       final hargaJual = double.tryParse(_hargaJualController.text) ?? 0.0;
//       if (hargaJual > 0) {
//         setState(() {
//           _foodCostPercentage = (_totalRecipeCost / hargaJual) * 100;
//         });
//       }
//     } else {
//       setState(() {
//         _foodCostPercentage = 0.0;
//       });
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final imageFile = await ImageHelper.showImageSourceDialog(context);
//     if (imageFile != null) {
//       setState(() {
//         _selectedImage = imageFile;
//         if (kIsWeb) {
//           _selectedImagePath = imageFile.path;
//         }
//       });
//     }
//   }
//
//   Future<void> _saveMenu() async {
//     // Validasi
//     if (_namaMenuController.text.isEmpty) {
//       Fluttertoast.showToast(
//         msg: "Nama menu harus diisi!",
//         backgroundColor: Colors.red,
//       );
//       return;
//     }
//
//     if (_kodeMenuController.text.isEmpty) {
//       Fluttertoast.showToast(
//         msg: "Kode menu harus diisi!",
//         backgroundColor: Colors.red,
//       );
//       return;
//     }
//
//     // Proses upload gambar
//     String imageUrl = '';
//     if (_selectedImage != null) {
//       try {
//         Fluttertoast.showToast(
//           msg: "Memproses gambar...",
//           backgroundColor: Colors.blue,
//         );
//
//         // Simpan lokal untuk mobile
//         if (!kIsWeb) {
//           final localPath = await ImageHelper.saveImageToAssets(
//             _selectedImage!,
//             _namaMenuController.text.replaceAll(' ', '_'),
//           );
//           if (localPath != null) {
//             imageUrl = localPath;
//           }
//         }
//
//         // Coba upload ke GoCloud
//         final cloudUrl = await ImageHelper.uploadImageToGoCloud(
//           imageFile: _selectedImage!,
//           token: token,
//           project: project,
//           fileName: _namaMenuController.text.replaceAll(' ', '_'),
//         );
//
//         if (cloudUrl != null && cloudUrl.isNotEmpty) {
//           imageUrl = cloudUrl;
//         } else {
//           // Fallback ke Base64
//           final base64Image = await ImageHelper.convertImageToBase64(_selectedImage!);
//           if (base64Image != null && base64Image.isNotEmpty) {
//             imageUrl = base64Image;
//           }
//         }
//       } catch (e) {
//         print('Error upload gambar: $e');
//       }
//     }
//
//     // Format data bahan baku
//     List<String> bahanList = [];
//     List<String> jumlahList = [];
//     List<String> satuanList = [];
//     List<String> biayaList = [];
//
//     for (var item in _selectedBahanBakuList) {
//       if (item['bahan'] != null) {
//         final BahanBakuModel bahan = item['bahan'];
//         bahanList.add(bahan.nama);
//         jumlahList.add(item['qty'].text);
//         satuanList.add(bahan.unit);
//         biayaList.add(item['cost'].toString());
//       }
//     }
//
//     // Insert ke database
//     try {
//       Fluttertoast.showToast(
//         msg: "Menyimpan menu...",
//         backgroundColor: Colors.blue,
//       );
//
//       final result = await _dataService.insertMenu(
//         appid,
//         _kodeMenuController.text,
//         _namaMenuController.text,
//         imageUrl,
//         _selectedKategori ?? '',
//         _hargaJualController.text,
//         _barcodeController.text,
//         bahanList.join(','),
//         jumlahList.join(','),
//         satuanList.join(','),
//         biayaList.join(','),
//         _catatanController.text,
//       );
//
//       print('Result insert menu: $result');
//
//       Fluttertoast.showToast(
//         msg: "Menu berhasil ditambahkan!",
//         backgroundColor: Colors.green,
//       );
//
//       widget.onMenuAdded();
//       Navigator.pop(context);
//
//     } catch (e) {
//       print('Error saving menu: $e');
//       Fluttertoast.showToast(
//         msg: "Gagal menyimpan menu: ${e.toString()}",
//         backgroundColor: Colors.red,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Tambah Menu'),
//         backgroundColor: Colors.green[700],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Icon Upload Gambar
//             Center(
//               child: GestureDetector(
//                 onTap: _pickImage,
//                 child: Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: Colors.green[700],
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       if (_selectedImage != null && !kIsWeb)
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(16),
//                           child: Image.file(
//                             _selectedImage!,
//                             width: 120,
//                             height: 120,
//                             fit: BoxFit.cover,
//                           ),
//                         )
//                       else if (_selectedImagePath != null && kIsWeb)
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(16),
//                           child: const Icon(Icons.image, size: 50, color: Colors.white),
//                         )
//                       else
//                         Icon(
//                           Icons.camera_alt,
//                           size: 50,
//                           color: Colors.white.withValues(alpha: 0.8),
//                         ),
//                       Positioned(
//                         bottom: 10,
//                         right: 10,
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: const BoxDecoration(
//                             color: Colors.white,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.add_circle,
//                             color: Colors.green[700],
//                             size: 24,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 30),
//
//             // Informasi Utama
//             _buildSectionTitle('Informasi Utama'),
//             const SizedBox(height: 16),
//
//             _buildTextField(
//               controller: _kodeMenuController,
//               label: 'Kode Menu',
//               hint: 'Masukkan kode menu',
//             ),
//
//             const SizedBox(height: 16),
//
//             _buildTextField(
//               controller: _namaMenuController,
//               label: 'Nama menu',
//               hint: 'Masukkan nama menu',
//             ),
//
//             const SizedBox(height: 16),
//
//             _buildDropdownField(
//               label: 'Kategori',
//               value: _selectedKategori,
//               items: ['Makanan', 'Minuman', 'Dessert', 'Snack'],
//               onChanged: (value) {
//                 setState(() {
//                   _selectedKategori = value;
//                 });
//               },
//             ),
//
//             const SizedBox(height: 16),
//
//             _buildTextField(
//               controller: _hargaJualController,
//               label: 'Harga Jual',
//               hint: 'Masukkan harga jual',
//               keyboardType: TextInputType.number,
//             ),
//
//             const SizedBox(height: 16),
//
//             _buildTextField(
//               controller: _barcodeController,
//               label: 'Barcode (Opsional)',
//               hint: 'Masukkan barcode',
//             ),
//
//             const SizedBox(height: 30),
//
//             // Ringkasan Perhitungan
//             _buildSectionTitle('Ringkasan Perhitungan'),
//             const SizedBox(height: 16),
//
//             _buildReadOnlyField(
//               label: 'Total Recipe Cost (otomatis)',
//               value: 'Rp${_formatNumber(_totalRecipeCost)}',
//             ),
//
//             const SizedBox(height: 16),
//
//             _buildReadOnlyField(
//               label: 'Food Cost % (otomatis)',
//               value: '${_foodCostPercentage.toStringAsFixed(1)}%',
//             ),
//
//             const SizedBox(height: 30),
//
//             // Daftar Bahan Baku
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildSectionTitle('Daftar Bahan Baku'),
//                 ElevatedButton.icon(
//                   onPressed: _addBahanBaku,
//                   icon: const Icon(Icons.add, size: 18),
//                   label: const Text('Tambah Bahan'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange[700],
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//
//             if (_isLoadingBahanBaku)
//               const Center(child: CircularProgressIndicator())
//             else if (_availableBahanBaku.isEmpty)
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Text(
//                     'Belum ada bahan baku. Silakan tambahkan bahan baku terlebih dahulu.',
//                     style: TextStyle(color: Colors.grey[600]),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               )
//             else
//               ..._selectedBahanBakuList.asMap().entries.map((entry) {
//                 return _buildBahanBakuCard(entry.key);
//               }),
//
//             const SizedBox(height: 30),
//
//             // Catatan
//             _buildSectionTitle('Catatan Tambahan (Opsional)'),
//             const SizedBox(height: 16),
//
//             TextField(
//               controller: _catatanController,
//               maxLines: 4,
//               decoration: InputDecoration(
//                 hintText: 'Tambahkan catatan...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.orange[300]!),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.orange[300]!),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 30),
//
//             // Submit Button
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton(
//                 onPressed: _saveMenu,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF8B4513),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'Simpan Menu',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//         color: Colors.orange[700],
//       ),
//     );
//   }
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     TextInputType? keyboardType,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           keyboardType: keyboardType,
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: TextStyle(color: Colors.grey[400]),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.orange[300]!),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.orange[300]!),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
//             ),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildReadOnlyField({
//     required String label,
//     required String value,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           decoration: BoxDecoration(
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey[300]!),
//           ),
//           child: Text(
//             value,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[700],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDropdownField({
//     required String label,
//     required String? value,
//     required List<String> items,
//     required Function(String?) onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 8),
//         DropdownButtonFormField<String>(
//           value: value,
//           decoration: InputDecoration(
//             hintText: 'Pilih $label',
//             hintStyle: TextStyle(color: Colors.grey[400]),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.orange[300]!),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.orange[300]!),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
//             ),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           ),
//           items: items.map((String item) {
//             return DropdownMenuItem<String>(
//               value: item,
//               child: Text(item),
//             );
//           }).toList(),
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBahanBakuCard(int index) {
//     final item = _selectedBahanBakuList[index];
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.orange[300]!),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withValues(alpha: 0.1),
//             spreadRadius: 1,
//             blurRadius: 3,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Bahan Baku ${index + 1}',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.delete, color: Colors.red),
//                 onPressed: () => _removeBahanBaku(index),
//                 padding: EdgeInsets.zero,
//                 constraints: const BoxConstraints(),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//
//           // Dropdown Bahan Baku
//           DropdownButtonFormField<BahanBakuModel>(
//             initialValue: item['bahan'],
//             decoration: InputDecoration(
//               hintText: 'Pilih bahan baku',
//               hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
//               filled: true,
//               fillColor: Colors.white,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: Colors.grey[300]!),
//               ),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             ),
//             items: _availableBahanBaku.map((BahanBakuModel bahan) {
//               return DropdownMenuItem<BahanBakuModel>(
//                 value: bahan,
//                 child: Text(
//                   '${bahan.nama} (${bahan.unit}) - Rp${bahan.harga_unit}',
//                   style: const TextStyle(fontSize: 14),
//                 ),
//               );
//             }).toList(),
//             onChanged: (BahanBakuModel? value) {
//               setState(() {
//                 item['bahan'] = value;
//                 item['satuan'] = value?.unit ?? '';
//                 _calculateTotalRecipeCost();
//               });
//             },
//           ),
//
//           const SizedBox(height: 12),
//
//           Row(
//             children: [
//               Expanded(
//                 flex: 2,
//                 child: TextField(
//                   controller: item['qty'],
//                   keyboardType: TextInputType.number,
//                   onChanged: (value) => _calculateTotalRecipeCost(),
//                   decoration: InputDecoration(
//                     labelText: 'Qty',
//                     labelStyle: const TextStyle(fontSize: 12),
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide(color: Colors.grey[300]!),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 flex: 2,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey[300]!),
//                   ),
//                   child: Text(
//                     item['satuan'] ?? '-',
//                     style: const TextStyle(fontSize: 14),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 flex: 3,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey[300]!),
//                   ),
//                   child: Text(
//                     'Rp${_formatNumber(item['cost'])}',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatNumber(double value) {
//     return value.toStringAsFixed(0).replaceAllMapped(
//       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//       (Match m) => '${m[1]}.',
//     );
//   }
// }
