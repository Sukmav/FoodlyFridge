// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'dart:convert';
// import 'dart:io';
// import '../restapi.dart';
// import '../config.dart';
// import '../model/menu_model.dart';
// import 'add_menu_form.dart';
// import 'menu_detail_page.dart';
//
// class MenuPage extends StatefulWidget {
//   const MenuPage({super.key});
//
//   @override
//   State<MenuPage> createState() => _MenuPageState();
// }
//
// class _MenuPageState extends State<MenuPage> {
//   final DataService _dataService = DataService();
//   List<MenuModel> _menuList = [];
//   List<MenuModel> _filteredList = [];
//   bool _isLoading = false;
//   final TextEditingController _searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadMenu();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadMenu() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       print('=== LOADING MENU ===');
//       final response = await _dataService.selectAll(
//         token,
//         project,
//         'menu',
//         appid,
//       );
//
//       print('Response: $response');
//
//       if (response == '[]' || response.isEmpty || response == 'null') {
//         print('Data kosong');
//         setState(() {
//           _menuList = [];
//           _filteredList = [];
//           _isLoading = false;
//         });
//         return;
//       }
//
//       final dynamic decodedData = json.decode(response);
//       List<dynamic> dataList;
//
//       if (decodedData is Map) {
//         if (decodedData.containsKey('data')) {
//           dataList = decodedData['data'] as List<dynamic>;
//         } else {
//           dataList = [decodedData];
//         }
//       } else if (decodedData is List) {
//         dataList = decodedData;
//       } else {
//         dataList = [];
//       }
//
//       print('Jumlah menu: ${dataList.length}');
//
//       final newList = dataList.map((json) => MenuModel.fromJson(json)).toList();
//
//       setState(() {
//         _menuList = newList;
//         _filteredList = List.from(_menuList);
//         _isLoading = false;
//       });
//
//       print('Menu berhasil dimuat: ${_menuList.length} items');
//
//     } catch (e, stackTrace) {
//       print('Error loading menu: $e');
//       print('StackTrace: $stackTrace');
//
//       setState(() {
//         _menuList = [];
//         _filteredList = [];
//         _isLoading = false;
//       });
//
//       Fluttertoast.showToast(
//         msg: "Gagal memuat menu: ${e.toString()}",
//         backgroundColor: Colors.red,
//       );
//     }
//   }
//
//   void _filterMenu(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredList = _menuList;
//       } else {
//         _filteredList = _menuList
//             .where((menu) =>
//                 menu.nama_menu.toLowerCase().contains(query.toLowerCase()) ||
//                 menu.kategori.toLowerCase().contains(query.toLowerCase()))
//             .toList();
//       }
//     });
//   }
//
//   void _showAddMenuForm() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AddMenuForm(onMenuAdded: _loadMenu),
//       ),
//     );
//   }
//
//   void _showMenuDetail(MenuModel menu) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => MenuDetailPage(
//           menu: menu,
//           onMenuUpdated: _loadMenu,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: _menuList.isEmpty && !_isLoading
//           ? _buildEmptyState()
//           : Column(
//               children: [
//                 // Search bar
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: TextField(
//                     controller: _searchController,
//                     onChanged: _filterMenu,
//                     decoration: InputDecoration(
//                       hintText: 'Cari menu...',
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.grey[300]!),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.grey[300]!),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.green[700]!, width: 2),
//                       ),
//                       filled: true,
//                       fillColor: Colors.white,
//                     ),
//                   ),
//                 ),
//                 // Grid Menu
//                 Expanded(
//                   child: _isLoading
//                       ? const Center(child: CircularProgressIndicator())
//                       : GridView.builder(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 2,
//                             childAspectRatio: 0.75,
//                             crossAxisSpacing: 12,
//                             mainAxisSpacing: 12,
//                           ),
//                           itemCount: _filteredList.length,
//                           itemBuilder: (context, index) {
//                             final menu = _filteredList[index];
//                             return _buildMenuCard(menu);
//                           },
//                         ),
//                 ),
//               ],
//             ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _showAddMenuForm,
//         backgroundColor: Colors.green[700],
//         icon: const Icon(Icons.add, color: Colors.white),
//         label: const Text('Tambah Menu', style: TextStyle(color: Colors.white)),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.restaurant_menu_outlined,
//             size: 120,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'Tidak Ada Menu',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Belum ada menu yang ditambahkan',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[500],
//             ),
//           ),
//           const SizedBox(height: 40),
//           ElevatedButton.icon(
//             onPressed: _showAddMenuForm,
//             icon: const Icon(Icons.add, color: Colors.white),
//             label: const Text(
//               'Tambah Menu',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green[700],
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMenuCard(MenuModel menu) {
//     return GestureDetector(
//       onTap: () => _showMenuDetail(menu),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image
//             ClipRRect(
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//               child: Container(
//                 height: 120,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                 ),
//                 child: _buildMenuImage(menu.foto_menu),
//               ),
//             ),
//             // Content
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           menu.nama_menu,
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Kode Menu : ${menu.id_menu}',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                     Text(
//                       'Harga: ${_formatRupiah(menu.harga_jual)}',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green[700],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMenuImage(String imagePath) {
//     if (imagePath.isEmpty) {
//       return Icon(
//         Icons.restaurant,
//         size: 50,
//         color: Colors.grey[400],
//       );
//     }
//
//     if (imagePath.startsWith('http')) {
//       return Image.network(
//         imagePath,
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return Icon(
//             Icons.restaurant,
//             size: 50,
//             color: Colors.grey[400],
//           );
//         },
//       );
//     } else if (imagePath.startsWith('data:image')) {
//       return Image.memory(
//         base64Decode(imagePath.split(',').last),
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return Icon(
//             Icons.restaurant,
//             size: 50,
//             color: Colors.grey[400],
//           );
//         },
//       );
//     } else if (!kIsWeb) {
//       return Image.file(
//         File(imagePath),
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return Icon(
//             Icons.restaurant,
//             size: 50,
//             color: Colors.grey[400],
//           );
//         },
//       );
//     }
//
//     return Icon(
//       Icons.restaurant,
//       size: 50,
//       color: Colors.grey[400],
//     );
//   }
//
//   String _formatRupiah(String value) {
//     if (value.isEmpty || value == '0') return 'Rp0';
//     try {
//       final number = int.parse(value);
//       return 'Rp${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
//     } catch (e) {
//       return 'Rp$value';
//     }
//   }
// }
