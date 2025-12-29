import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/staff.dart';
import '../config.dart';

class StaffService {
  final String _baseUrl = fileUri;
  final String _collection = 'staff';

  // Get semua staff untuk user tertentu
  Future<List<StaffModel>> getStaffByUserId(String userId) async {
    try {
      if (kDebugMode) {
        print('========== FETCHING STAFF FROM GOCLOUD ==========');
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
              print('No staff found - empty response');
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
              print('No staff found for this user');
            }
            return [];
          }

          List<StaffModel> staffList = [];
          for (var data in dataList) {
            try {
              final staff = StaffModel.fromJson(Map<String, dynamic>.from(data));
              staffList.add(staff);
              if (kDebugMode) {
                print('Parsed: ${staff.nama_staff}');
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing item: $e');
                print('Item data: $data');
              }
            }
          }

          if (kDebugMode) {
            print('Found ${staffList.length} staff items');
          }
          return staffList;
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('Error parsing response: $e');
            print('Stack trace: $stackTrace');
          }
          return [];
        }
      } else {
        if (kDebugMode) {
          print('Failed to fetch staff. Status: ${response.statusCode}');
        }
        return [];
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getStaffByUserId: $e');
        print('Stack trace: $stackTrace');
      }
      return [];
    }
  }

  // Tambah staff baru
  Future<bool> addStaff({
    required String userId,
    required String namaStaff,
    required String email,
    required String password,
    required String jabatan,
    String? fotoProfile,
  }) async {
    try {
      if (kDebugMode) {
        print('========== ADDING STAFF TO GOCLOUD ==========');
        print('User ID: $userId');
        print('Nama Staff: $namaStaff');
        print('Email: $email');
        print('Jabatan: $jabatan');
      }

      final uri = '$_baseUrl/insert/';

      final body = {
        'token': token,
        'project': project,
        'collection': _collection,
        'appid': appid,
        'user_id': userId,
        'nama_staff': namaStaff,
        'email': email,
        'kata_sandi': password, // Field name sesuai dengan model
        'jabatan': jabatan,
        'foto': fotoProfile ?? '', // Tambahkan foto field
      };

      // Tidak perlu check foto_profile karena sudah ada field 'foto'

      final response = await http.post(
        Uri.parse(uri),
        body: body,
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Staff added successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to add staff. Status: ${response.statusCode}');
        }
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in addStaff: $e');
        print('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  // Update staff
  Future<bool> updateStaff({
    required String staffId,
    required String userId,
    String? namaStaff,
    String? email,
    String? password,
    String? jabatan,
    String? fotoProfile,
  }) async {
    try {
      if (kDebugMode) {
        print('========== UPDATING STAFF IN GOCLOUD ==========');
        print('Staff ID: $staffId');
        print('User ID: $userId');
      }

      final uri = '$_baseUrl/update/';

      final body = {
        'token': token,
        'project': project,
        'collection': _collection,
        'appid': appid,
        '_id': staffId,
        'user_id': userId,
      };

      if (namaStaff != null) body['nama_staff'] = namaStaff;
      if (email != null) body['email'] = email;
      if (password != null) body['kata_sandi'] = password; // Field name sesuai dengan model
      if (jabatan != null) body['jabatan'] = jabatan;
      if (fotoProfile != null) body['foto'] = fotoProfile; // Field name sesuai dengan model

      final response = await http.post(
        Uri.parse(uri),
        body: body,
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Staff updated successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to update staff. Status: ${response.statusCode}');
        }
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in updateStaff: $e');
        print('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  // Hapus staff
  Future<bool> deleteStaff(String staffId) async {
    try {
      if (kDebugMode) {
        print('========== DELETING STAFF FROM GOCLOUD ==========');
        print('Staff ID: $staffId');
      }

      final uri = '$_baseUrl/delete/';
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          '_id': staffId,
        },
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Staff deleted successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to delete staff. Status: ${response.statusCode}');
        }
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in deleteStaff: $e');
        print('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  // Authenticate staff by email and password
  Future<StaffModel?> authenticateStaff({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('========== AUTHENTICATING STAFF ==========');
        print('Email: $email');
      }

      final uri = '$_baseUrl/select/';
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          'email': email,
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
              print('No staff found with this email');
            }
            return null;
          }

          final responseData = json.decode(response.body);

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
              print('No staff found with this email');
            }
            return null;
          }

          // Get the first staff with matching email
          final staffData = Map<String, dynamic>.from(dataList.first);
          final staff = StaffModel.fromJson(staffData);

          // Verify password
          if (staff.kata_sandi == password) {
            if (kDebugMode) {
              print('Staff authenticated successfully');
              print('Staff Name: ${staff.nama_staff}');
              print('Jabatan: ${staff.jabatan}');
            }
            return staff;
          } else {
            if (kDebugMode) {
              print('Invalid password');
            }
            return null;
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('Error parsing response: $e');
            print('Stack trace: $stackTrace');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('Failed to authenticate staff. Status: ${response.statusCode}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in authenticateStaff: $e');
        print('Stack trace: $stackTrace');
      }
      return null;
    }
  }

  // Get staff owner's user_id
  Future<String?> getStaffOwnerUserId(String staffId) async {
    try {
      if (kDebugMode) {
        print('========== GETTING STAFF OWNER USER ID ==========');
        print('Staff ID: $staffId');
      }

      final uri = '$_baseUrl/select/';
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          '_id': staffId,
        },
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        try {
          if (response.body.isEmpty || response.body == 'null' || response.body == '[]') {
            return null;
          }

          final responseData = json.decode(response.body);

          if (responseData is Map && responseData.containsKey('user_id')) {
            return responseData['user_id'] as String;
          } else if (responseData is List && responseData.isNotEmpty) {
            final firstItem = responseData.first as Map<dynamic, dynamic>;
            return firstItem['user_id'] as String?;
          }

          return null;
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error parsing response: $e');
          }
          return null;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getStaffOwnerUserId: $e');
      }
      return null;
    }
  }
}

