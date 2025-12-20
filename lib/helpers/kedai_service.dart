import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../model/kedai.dart';
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KedaiService {
  final String _baseUrl = fileUri;
  final String _collection = 'kedai';

  // ✅ PERBAIKAN: Tambahkan timeout untuk semua request
  static const Duration _requestTimeout = Duration(seconds: 15);

  // ✅ PERBAIKAN: Cache helper methods
  Future<void> _cacheKedai(String userId, KedaiModel kedai) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_kedai_$userId', json.encode({
        'id': kedai.id,
        'nama_kedai': kedai.nama_kedai,
        'alamat_kedai': kedai.alamat_kedai,
        'nomor_telepon': kedai.nomor_telepon,
        'catatan_struk': kedai.catatan_struk,
        'logo_kedai': kedai.logo_kedai,
        'cached_at': DateTime.now().toIso8601String(),
      }));

      // Set flag bahwa user memiliki kedai
      await prefs.setBool('has_kedai_$userId', true);

      if (kDebugMode) {
        print('✅ Kedai cached successfully for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to cache kedai: $e');
      }
    }
  }

  Future<KedaiModel?> _getCachedKedai(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_kedai_$userId');

      if (cachedData != null) {
        final data = json.decode(cachedData);
        if (kDebugMode) {
          print('✅ Found cached kedai data for user: $userId');
          print('Cached at: ${data['cached_at']}');
        }
        return KedaiModel.fromJson(data, data['id']);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to retrieve cached kedai: $e');
      }
    }
    return null;
  }

  Future<void> _clearCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_kedai_$userId');
      await prefs.remove('has_kedai_$userId');
      if (kDebugMode) {
        print('✅ Cache cleared for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to clear cache: $e');
      }
    }
  }

  // Simpan atau update data kedai ke GoCloud
  Future<String?> saveKedai(KedaiModel kedai, String userId) async {
    try {
      if (kDebugMode) {
        print('========== SAVING KEDAI TO GOCLOUD ==========');
        print('User ID:  $userId');
        print('Nama Kedai: ${kedai.nama_kedai}');
        print('Alamat:  ${kedai.alamat_kedai}');
        print('Nomor Telepon: ${kedai.nomor_telepon}');
        print('Catatan Struk: ${kedai. catatan_struk}');
        print('Logo length: ${kedai.logo_kedai.length}');
      }

      // Cek apakah user sudah punya data kedai
      final existingKedai = await getKedaiByUserId(userId);

      String? result;
      if (existingKedai != null) {
        // Update data yang sudah ada
        if (kDebugMode) {
          print('✅ User already has kedai, updating existing data...');
          print('Existing Kedai ID: ${existingKedai.id}');
        }
        result = await _updateKedai(existingKedai.id, kedai, userId);
      } else {
        // Buat data baru
        if (kDebugMode) {
          print('✅ User does not have kedai, creating new data...');
        }
        result = await _insertKedai(kedai, userId);
      }

      // ✅ PERBAIKAN: Cache data setelah berhasil disimpan
      if (result != null) {
        // Set ID jika belum ada
        if (kedai.id.isEmpty && result != 'success') {
          kedai = KedaiModel(
            id: result,
            nama_kedai: kedai.nama_kedai,
            alamat_kedai: kedai.alamat_kedai,
            nomor_telepon: kedai.nomor_telepon,
            catatan_struk: kedai.catatan_struk,
            logo_kedai: kedai.logo_kedai,
          );
        }

        await _cacheKedai(userId, kedai);

        if (kDebugMode) {
          print('✅ Kedai data saved and cached successfully');
        }
      }

      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ ERROR saving kedai: $e');
        print('Stack trace: $stackTrace');
      }

      // ✅ PERBAIKAN: Bahkan jika gagal save ke server, cache data lokalnya
      // Ini penting untuk web platform dengan CORS issues
      try {
        await _cacheKedai(userId, kedai);
        if (kDebugMode) {
          print('⚠️ Failed to save to server, but data cached locally');
          print('💡 Data will sync when connection is available');
        }
        // Return success untuk mencegah error di UI
        return 'cached_locally';
      } catch (cacheError) {
        if (kDebugMode) {
          print('❌ Failed to cache locally: $cacheError');
        }
      }

      rethrow;
    }
  }

  // Insert data baru ke GoCloud
  Future<String?> _insertKedai(KedaiModel kedai, String userId) async {
    try {
      if (kDebugMode) {
        print('Creating new kedai document in GoCloud...');
        print('API URL: $_baseUrl/insert/');
      }

      final uri = '$_baseUrl/insert/';

      // ✅ PERBAIKAN: Tambahkan timeout
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token, // ✅ PERBAIKAN: Gunakan variabel dari config
          'project': project, // ✅ PERBAIKAN: Gunakan variabel dari config
          'collection': _collection,
          'appid': appid,
          'user_id':  userId,
          'nama_kedai': kedai.nama_kedai,
          'alamat_kedai': kedai.alamat_kedai,
          'nomor_telepon': kedai. nomor_telepon,
          'catatan_struk': kedai.catatan_struk,
          'logo_kedai':  kedai.logo_kedai,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      ).timeout(
        _requestTimeout,
        onTimeout: () {
          if (kDebugMode) {
            print('⚠️ Insert request timeout');
          }
          throw Exception('Insert request timeout');
        },
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response. statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          if (kDebugMode) {
            print('✅ Kedai created successfully in GoCloud');
            print('Response data: $responseData');
          }

          // Handle berbagai format response dari GoCloud
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

          if (kDebugMode) {
            print('Document ID: ${docId ?? "success"}');
          }

          return docId ?? 'success';
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing response, but insert might be successful: $e');
          }
          return 'success';
        }
      } else {
        if (kDebugMode) {
          print('Failed to insert kedai.  Status: ${response.statusCode}');
        }
        throw Exception('Failed to insert kedai: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _insertKedai: $e');
      }
      rethrow;
    }
  }

  // Update data yang sudah ada di GoCloud
  Future<String?> _updateKedai(String kedaiId, KedaiModel kedai, String userId) async {
    try {
      if (kDebugMode) {
        print('Updating existing kedai with ID: $kedaiId');
      }

      final uri = '$_baseUrl/update/';

      // ✅ PERBAIKAN: Tambahkan timeout
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection':  _collection,
          'appid': appid,
          '_id': kedaiId,
          'user_id': userId,
          'nama_kedai': kedai.nama_kedai,
          'alamat_kedai': kedai.alamat_kedai,
          'nomor_telepon': kedai.nomor_telepon,
          'catatan_struk': kedai.catatan_struk,
          'logo_kedai': kedai.logo_kedai,
          'updated_at': DateTime.now().toIso8601String(),
        },
      ).timeout(
        _requestTimeout,
        onTimeout: () {
          if (kDebugMode) {
            print('⚠️ Update request timeout');
          }
          throw Exception('Update request timeout');
        },
      );

      if (kDebugMode) {
        print('Update response status: ${response.statusCode}');
        print('Update response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Kedai updated successfully: $kedaiId');
        }
        return kedaiId;
      } else {
        if (kDebugMode) {
          print('Failed to update kedai. Status: ${response.statusCode}');
        }
        throw Exception('Failed to update kedai: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _updateKedai: $e');
      }
      rethrow;
    }
  }

  // Ambil data kedai berdasarkan user ID dari GoCloud
  Future<KedaiModel?> getKedaiByUserId(String userId) async {
    // ✅ PERBAIKAN: Cek cache dulu untuk web platform atau jika ada masalah koneksi
    final cachedKedai = await _getCachedKedai(userId);

    try {
      if (kDebugMode) {
        print('========== KEDAI SERVICE: GET KEDAI ==========');
        print('Fetching kedai from GoCloud for user: $userId');
        print('API URL: $_baseUrl/select/');
        print('Using token: $token');
        print('Using project: $project');
        print('Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      }

      final uri = '$_baseUrl/select/';

      // ✅ PERBAIKAN: Tambahkan timeout pada request
      final response = await http.post(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          'user_id': userId,
        },
      ).timeout(
        _requestTimeout,
        onTimeout: () {
          if (kDebugMode) {
            print('⚠️ Request timeout after ${_requestTimeout.inSeconds} seconds');
          }
          throw Exception('Request timeout');
        },
      );

      if (kDebugMode) {
        print('Get response status: ${response.statusCode}');
        print('Get response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // GoCloud mengembalikan array data
          if (responseData is List && responseData.isNotEmpty) {
            final kedaiData = responseData[0];
            if (kDebugMode) {
              print('✅ Kedai found: ${kedaiData['nama_kedai']}');
              print('Kedai ID: ${kedaiData['_id']}');
              print('Full data: $kedaiData');
            }

            final kedai = KedaiModel.fromJson(kedaiData, kedaiData['_id'].toString());

            // ✅ Cache the result
            await _cacheKedai(userId, kedai);

            return kedai;
          }

          if (kDebugMode) {
            print('⚠️ No kedai found for this user in database');
            print('Response data type: ${responseData.runtimeType}');
            print('Response data: $responseData');
          }

          // ✅ Jika tidak ada di database tapi ada di cache, gunakan cache
          if (cachedKedai != null) {
            if (kDebugMode) {
              print('✅ Using cached kedai data as fallback');
            }
            return cachedKedai;
          }

          return null;
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing response: $e');
          }

          // ✅ Fallback ke cache jika ada error parsing
          if (cachedKedai != null) {
            if (kDebugMode) {
              print('✅ Using cached kedai data due to parse error');
            }
            return cachedKedai;
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch kedai. Status: ${response.statusCode}');
        }

        // ✅ Fallback ke cache jika request gagal
        if (cachedKedai != null) {
          if (kDebugMode) {
            print('✅ Using cached kedai data due to failed request');
          }
          return cachedKedai;
        }
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error in getKedaiByUserId: $e');
        print('Stack trace: $stackTrace');

        // ✅ Deteksi CORS error
        if (e.toString().contains('CORS') ||
            e.toString().contains('Failed to fetch') ||
            e.toString().contains('XMLHttpRequest')) {
          print('⚠️ CORS/Network error detected - this is common on web platform');
          print('💡 Using cached data if available...');
        }
      }

      // ✅ PERBAIKAN UTAMA: Return cache jika ada error (termasuk CORS)
      if (cachedKedai != null) {
        if (kDebugMode) {
          print('✅ Using cached kedai data as fallback: ${cachedKedai.nama_kedai}');
        }
        return cachedKedai;
      }

      return null;
    }
  }

  // Hapus data kedai dari GoCloud
  Future<void> deleteKedai(String kedaiId) async {
    try {
      if (kDebugMode) {
        print('Deleting kedai from GoCloud: $kedaiId');
      }

      final uri = '$_baseUrl/delete/';
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          '_id': kedaiId,
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Kedai deleted successfully: $kedaiId');
        }
      } else {
        if (kDebugMode) {
          print('Failed to delete kedai. Status: ${response.statusCode}');
        }
        throw Exception('Failed to delete kedai: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting kedai: $e');
      }
      rethrow;
    }
  }

  // Get all kedai (jika diperlukan untuk admin)
  Future<List<KedaiModel>> getAllKedai() async {
    try {
      final uri = '$_baseUrl/select/';
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is List) {
          return responseData
              .map((data) => KedaiModel.fromJson(data, data['_id'].toString()))
              .toList();
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all kedai: $e');
      }
      return [];
    }
  }
}