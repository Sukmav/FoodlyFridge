// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'dart:convert';
// import 'dart:io';
// import '../restapi.dart';
// import '../config.dart';
// import '../model/menu_model.dart';
//
// class MenuDetailPage extends StatefulWidget {
//   const MenuDetailPage({super.key, required this.menu, required this.onMenuUpdated});
//
//   final MenuModel menu;
//   final VoidCallback onMenuUpdated;
//
//   @override
//   State<MenuDetailPage> createState() => _MenuDetailPageState();
// }
//
// class _MenuDetailPageState extends State<MenuDetailPage> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final DataService _dataService = DataService();
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _deleteMenu() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Hapus Menu?'),
//         content: Text('Apakah Anda yakin ingin menghapus "${widget.menu.nama_menu}"?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Batal'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Hapus'),
//           ),
//         ],
//       ),
//     );
//
//     if (confirm != true) return;
//
//     try {
//       await _dataService.removeWhere(
//         token,
//         project,
//         'menu',
//         appid,
//         'id_menu',
//         widget.menu.id_menu,
//       );
//
//       Fluttertoast.showToast(
//         msg: "Menu berhasil dihapus!",
//         backgroundColor: Colors.green,
//       );
//
//       widget.onMenuUpdated();
//       Navigator.pop(context);
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Gagal menghapus menu: ${e.toString()}",
//         backgroundColor: Colors.red,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: CustomScrollView(
//         slivers: [
//           // App Bar dengan Gambar
//           SliverAppBar(
//             expandedHeight: 200,
//             pinned: true,
//             backgroundColor: Colors.green[700],
//             flexibleSpace: FlexibleSpaceBar(
//               background: _buildMenuImage(widget.menu.foto_menu),
//             ),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.delete),
//                 onPressed: _deleteMenu,
//               ),
//             ],
//           ),
//
//           // Content
//           SliverToBoxAdapter(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Menu Header Info
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               widget.menu.nama_menu,
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Kode: ${widget.menu.id_menu}',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Tab Bar
//                 Container(
//                   color: Colors.grey[100],
//                   child: TabBar(
//                     controller: _tabController,
//                     labelColor: Colors.orange[700],
//                     unselectedLabelColor: Colors.grey[600],
//                     indicatorColor: Colors.orange[700],
//                     tabs: const [
//                       Tab(text: 'Detail'),
//                       Tab(text: 'Riwayat'),
//                     ],
//                   ),
//                 ),
//
//                 // Tab Bar View Content
//                 Container(
//                   height: MediaQuery.of(context).size.height - 400,
//                   padding: const EdgeInsets.all(20),
//                   child: TabBarView(
//                     controller: _tabController,
//                     children: [
//                       _buildDetailTab(),
//                       _buildRiwayatTab(),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDetailTab() {
//     // Parse bahan baku dari string
//     final bahanList = widget.menu.bahan.split(',');
//     final jumlahList = widget.menu.jumlah.split(',');
//     final satuanList = widget.menu.satuan.split(',');
//     final biayaList = widget.menu.biaya.split(',');
//
//     // Hitung total recipe cost
//     double totalRecipeCost = 0.0;
//     for (var biaya in biayaList) {
//       if (biaya.isNotEmpty) {
//         totalRecipeCost += double.tryParse(biaya) ?? 0.0;
//       }
//     }
//
//     // Hitung food cost percentage
//     double foodCostPercentage = 0.0;
//     if (widget.menu.harga_jual.isNotEmpty) {
//       final hargaJual = double.tryParse(widget.menu.harga_jual) ?? 0.0;
//       if (hargaJual > 0) {
//         foodCostPercentage = (totalRecipeCost / hargaJual) * 100;
//       }
//     }
//
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Informasi Utama
//           _buildSectionTitle('Informasi Utama'),
//           const SizedBox(height: 12),
//           _buildInfoCard([
//             _buildInfoRow('Kategori', widget.menu.kategori.isEmpty ? 'Hidangan Utama' : widget.menu.kategori),
//             _buildInfoRow('Harga Jual', 'Rp${_formatNumber(widget.menu.harga_jual)}'),
//             _buildInfoRow('Total Recipe Cost', 'Rp${_formatNumber(totalRecipeCost.toString())}'),
//             _buildInfoRow('Food Cost %', '${foodCostPercentage.toStringAsFixed(1)}%'),
//           ]),
//
//           const SizedBox(height: 24),
//
//           // Barcode
//           if (widget.menu.barcode.isNotEmpty) ...[
//             _buildSectionTitle('Barcode'),
//             const SizedBox(height: 12),
//             Center(
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.orange[300]!),
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       height: 60,
//                       width: 200,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Center(
//                         child: Text(
//                           widget.menu.barcode,
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             fontFamily: 'Courier',
//                             color: Colors.grey[800],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       widget.menu.barcode,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         // TODO: Implement download barcode
//                       },
//                       icon: const Icon(Icons.download, size: 18),
//                       label: const Text('Unduh Barcode'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange[700],
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//           ],
//
//           // Daftar Bahan Baku
//           _buildSectionTitle('Daftar Bahan Baku'),
//           const SizedBox(height: 12),
//
//           if (bahanList.isEmpty || bahanList.first.isEmpty)
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   'Tidak ada bahan baku',
//                   style: TextStyle(color: Colors.grey[600]),
//                 ),
//               ),
//             )
//           else
//             Column(
//               children: [
//                 // Header Table
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.orange[700],
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                   ),
//                   child: const Row(
//                     children: [
//                       Expanded(flex: 3, child: Text('Bahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//                       Expanded(flex: 2, child: Text('Qty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
//                       Expanded(flex: 2, child: Text('Satuan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
//                       Expanded(flex: 2, child: Text('Cost', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
//                     ],
//                   ),
//                 ),
//                 // Table Content
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: Colors.orange[300]!),
//                     borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
//                   ),
//                   child: Column(
//                     children: List.generate(bahanList.length, (index) {
//                       if (index >= bahanList.length) return const SizedBox.shrink();
//
//                       final bahan = index < bahanList.length ? bahanList[index] : '';
//                       final jumlah = index < jumlahList.length ? jumlahList[index] : '';
//                       final satuan = index < satuanList.length ? satuanList[index] : '';
//                       final biaya = index < biayaList.length ? biayaList[index] : '0';
//
//                       return Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                         decoration: BoxDecoration(
//                           border: Border(
//                             bottom: BorderSide(
//                               color: index < bahanList.length - 1 ? Colors.grey[300]! : Colors.transparent,
//                             ),
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               flex: 3,
//                               child: Text(
//                                 bahan,
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                             ),
//                             Expanded(
//                               flex: 2,
//                               child: Text(
//                                 jumlah,
//                                 style: const TextStyle(fontSize: 14),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                             Expanded(
//                               flex: 2,
//                               child: Text(
//                                 satuan,
//                                 style: const TextStyle(fontSize: 14),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                             Expanded(
//                               flex: 2,
//                               child: Text(
//                                 'Rp${_formatNumber(biaya)}',
//                                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//                                 textAlign: TextAlign.right,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                   ),
//                 ),
//                 // Total
//                 Container(
//                   margin: const EdgeInsets.only(top: 8),
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.green[50],
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.green[300]!),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Total Recipe Cost',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         'Rp${_formatNumber(totalRecipeCost.toString())}',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green[700],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//
//           const SizedBox(height: 24),
//
//           // Catatan
//           if (widget.menu.catatan.isNotEmpty) ...[
//             _buildSectionTitle('Catatan'),
//             const SizedBox(height: 12),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey[300]!),
//               ),
//               child: Text(
//                 widget.menu.catatan,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[700],
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRiwayatTab() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.history,
//             size: 64,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Belum ada riwayat',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//         color: Colors.orange[700],
//       ),
//     );
//   }
//
//   Widget _buildInfoCard(List<Widget> children) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.orange[300]!),
//       ),
//       child: Column(
//         children: children,
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMenuImage(String imagePath) {
//     if (imagePath.isEmpty) {
//       return Container(
//         color: Colors.grey[300],
//         child: Icon(
//           Icons.restaurant,
//           size: 80,
//           color: Colors.grey[500],
//         ),
//       );
//     }
//
//     if (imagePath.startsWith('http')) {
//       return Image.network(
//         imagePath,
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return Container(
//             color: Colors.grey[300],
//             child: Icon(
//               Icons.restaurant,
//               size: 80,
//               color: Colors.grey[500],
//             ),
//           );
//         },
//       );
//     } else if (imagePath.startsWith('data:image')) {
//       return Image.memory(
//         base64Decode(imagePath.split(',').last),
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return Container(
//             color: Colors.grey[300],
//             child: Icon(
//               Icons.restaurant,
//               size: 80,
//               color: Colors.grey[500],
//             ),
//           );
//         },
//       );
//     } else if (!kIsWeb) {
//       return Image.file(
//         File(imagePath),
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return Container(
//             color: Colors.grey[300],
//             child: Icon(
//               Icons.restaurant,
//               size: 80,
//               color: Colors.grey[500],
//             ),
//           );
//         },
//       );
//     }
//
//     return Container(
//       color: Colors.grey[300],
//       child: Icon(
//         Icons.restaurant,
//         size: 80,
//         color: Colors.grey[500],
//       ),
//     );
//   }
//
//   String _formatNumber(String value) {
//     if (value.isEmpty || value == '0') return '0';
//     try {
//       final number = double.parse(value);
//       return number.toStringAsFixed(0).replaceAllMapped(
//         RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//         (Match m) => '${m[1]}.',
//       );
//     } catch (e) {
//       return value;
//     }
//   }
// }
//
