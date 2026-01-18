//lib/helpers/menu_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/menu_model.dart';
import '../config.dart';

class MenuService {
  final String _baseUrl = fileUri;
  final String _collection = 'menu';

  // Get semua menu untuk user tertentu
  Future<List<MenuModel>> getMenuByUserId(String userId) async {
    try {
      if (kDebugMode) {
        print('========== FETCHING MENU FROM GOCLOUD ==========');
        print('User ID: $userId');
        print('API URL: $_baseUrl/select/');
      }

      final uri = '$_baseUrl/select/';
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          'user_id': userId,
        },
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        try {
          if (response.body.isEmpty || response.body == 'null' || response.body == '[]') {
            if (kDebugMode) {
              print('No menu found - empty response');
            }
            return [];
          }

          final responseData = json.decode(response.body);

          if (kDebugMode) {
            print('Response data type: ${responseData.runtimeType}');
          }

          List<dynamic> dataList = [];

          if (responseData is List) {
            dataList = responseData;
          } else if (responseData is Map) {
            if (responseData.containsKey('data')) {
              dataList = responseData['data'] is List ? responseData['data'] : [responseData['data']];
            } else {
              dataList = [responseData];
            }
          }

          if (dataList.isEmpty) {
            if (kDebugMode) {
              print('No menu found for this user');
            }
            return [];
          }

          List<MenuModel> menuList = [];
          for (var data in dataList) {
            try {
              final menu = MenuModel.fromJson(data as Map<dynamic, dynamic>);
              menuList.add(menu);
              if (kDebugMode) {
                print('✅ Parsed: ${menu.nama_menu}');
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error parsing item: $e');
                print('Item data: $data');
              }
            }
          }

          if (kDebugMode) {
            print('✅ Found ${menuList.length} menu items');
          }
          return menuList;
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('⚠️ Error parsing response: $e');
            print('Stack trace: $stackTrace');
          }
          return [];
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch menu. Status: ${response.statusCode}');
        }
        return [];
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error in getMenuByUserId: $e');
        print('Stack trace: $stackTrace');
      }
      return [];
    }
  }

  // Tambah menu baru
  Future<String?> addMenu(MenuModel menu, String userId) async {
    try {
      if (kDebugMode) {
        print('========== ADDING MENU TO GOCLOUD ==========');
        print('User ID: $userId');
        print('Nama Menu: ${menu.nama_menu}');
      }

      final uri = '$_baseUrl/insert/';
      final menuData = menu.toJson();

      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          'user_id': userId,
          'kode_menu': menu.kode_menu,
          'nama_menu': menu.nama_menu,
          'kategori': menu.kategori,
          'harga': menu.harga,
          'stok': menu.stok,
          'bahan_baku': json.encode(menuData['bahan_baku']),
          'foto_menu': menu.foto_menu,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          if (kDebugMode) {
            print('✅ Menu added successfully');
            print('Response data: $responseData');
          }

          String? docId;
          if (responseData is Map) {
            docId = responseData['_id']?.toString() ??
                    responseData['id']?.toString() ??
                    responseData['insertedId']?.toString();
          } else if (responseData is List && responseData.isNotEmpty) {
            final firstItem = responseData[0];
            if (firstItem is Map) {
              docId = firstItem['_id']?.toString() ??
                      firstItem['id']?.toString();
            }
          }

          return docId ?? 'success';
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error parsing response, but insert might be successful: $e');
          }
          return 'success';
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to add menu. Status: ${response.statusCode}');
        }
        throw Exception('Failed to add menu: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in addMenu: $e');
      }
      rethrow;
    }
  }

  // Update menu
  Future<String?> updateMenu(String id, MenuModel menu, String userId) async {
    try {
      if (kDebugMode) {
        print('========== UPDATING MENU ==========');
        print('ID: $id');
        print('User ID: $userId');
      }

      final uri = '$_baseUrl/update/';
      final menuData = menu.toJson();

      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          '_id': id,
          'user_id': userId,
          'kode_menu': menu.kode_menu,
          'nama_menu': menu.nama_menu,
          'kategori': menu.kategori,
          'harga': menu.harga,
          'stok': menu.stok,
          'bahan_baku': json.encode(menuData['bahan_baku']),
          'foto_menu': menu.foto_menu,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Menu updated successfully');
        }
        return id;
      } else {
        if (kDebugMode) {
          print('❌ Failed to update menu. Status: ${response.statusCode}');
        }
        throw Exception('Failed to update menu: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in updateMenu: $e');
      }
      rethrow;
    }
  }

  // Delete menu
  Future<void> deleteMenu(String id) async {
    try {
      if (kDebugMode) {
        print('========== DELETING MENU ==========');
        print('ID: $id');
      }

      final uri = '$_baseUrl/delete/';
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          '_id': id,
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Menu deleted successfully');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to delete menu. Status: ${response.statusCode}');
        }
        throw Exception('Failed to delete menu: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in deleteMenu: $e');
      }
      rethrow;
    }
  }
}

