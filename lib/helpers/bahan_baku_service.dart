import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/bahan_baku_model.dart';
import '../config.dart';

class BahanBakuService {
  final String _baseUrl = fileUri;
  final String _collection = 'bahan_baku';

  // Get semua bahan baku untuk user tertentu
  Future<List<BahanBakuModel>> getBahanBakuByUserId(String userId) async {
    try {
      if (kDebugMode) {
        print('========== FETCHING BAHAN BAKU FROM GOCLOUD ==========');
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
              print('No bahan baku found - empty response');
            }
            return [];
          }

          final responseData = json.decode(response.body);

          if (kDebugMode) {
            print('Response data type: ${responseData.runtimeType}');
          }

          if (responseData is List) {
            final bahanBakuList = responseData
                .map((data) => BahanBakuModel.fromJson(data))
                .toList();

            if (kDebugMode) {
              print('✅ Successfully fetched ${bahanBakuList.length} bahan baku items');
            }

            return bahanBakuList;
          } else if (responseData is Map) {
            if (kDebugMode) {
              print('Single bahan baku item received');
            }
            return [BahanBakuModel.fromJson(responseData)];
          } else {
            if (kDebugMode) {
              print('❌ Unexpected response format: ${responseData.runtimeType}');
            }
            return [];
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing bahan baku data: $e');
          }
          return [];
        }
      } else {
        if (kDebugMode) {
          print('❌ Server error: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in getBahanBakuByUserId: $e');
      }
      return [];
    }
  }

  // Get all bahan baku (without user_id filter)
  Future<List<BahanBakuModel>> getAllBahanBaku() async {
    try {
      if (kDebugMode) {
        print('========== FETCHING ALL BAHAN BAKU FROM GOCLOUD ==========');
        print('API URL: $_baseUrl/select/');
        print('Request body:');
        print('  - token: $token');
        print('  - project: $project');
        print('  - collection: $_collection');
        print('  - appid: $appid');
      }

      final uri = '$_baseUrl/select/';
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          // No user_id - get all data
        },
      );

      if (kDebugMode) {
        print('─────────────────────────────────────────────────────────');
        print('API Response:');
        print('  Status code: ${response.statusCode}');
        print('  Response body length: ${response.body.length} characters');
        print('  Response body preview (first 200 chars):');
        print('  ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        if (response.body.length > 200) {
          print('  ... (truncated)');
        }
        print('─────────────────────────────────────────────────────────');
      }

      if (response.statusCode == 200) {
        try {
          if (response.body.isEmpty || response.body == 'null' || response.body == '[]') {
            if (kDebugMode) {
              print('⚠️ No bahan baku found - empty response');
            }
            return [];
          }

          final responseData = json.decode(response.body);

          if (kDebugMode) {
            print('Decoded response type: ${responseData.runtimeType}');
          }

          if (responseData is List) {
            if (kDebugMode) {
              print('✅ Response is a List with ${responseData.length} items');
            }

            final bahanBakuList = responseData
                .map((data) => BahanBakuModel.fromJson(data))
                .toList();

            if (kDebugMode) {
              print('✅ Successfully parsed ${bahanBakuList.length} bahan baku items');
              if (bahanBakuList.isNotEmpty) {
                print('Sample items:');
                for (var i = 0; i < (bahanBakuList.length > 3 ? 3 : bahanBakuList.length); i++) {
                  print('  ${i + 1}. ${bahanBakuList[i].nama_bahan} (${bahanBakuList[i].unit})');
                }
              }
            }

            return bahanBakuList;
          } else if (responseData is Map) {
            if (kDebugMode) {
              print('⚠️ Response is a Map (single item), converting to List');
            }
            return [BahanBakuModel.fromJson(responseData)];
          } else {
            if (kDebugMode) {
              print('❌ Unexpected response format: ${responseData.runtimeType}');
            }
            return [];
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing bahan baku data: $e');
          }
          return [];
        }
      } else {
        if (kDebugMode) {
          print('❌ Server error: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in getAllBahanBaku: $e');
      }
      return [];
    }
  }
}

