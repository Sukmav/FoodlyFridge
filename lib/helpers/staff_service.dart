//lib/helpers/staff_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        print('========== ADDING STAFF TO GOCLOUD & FIREBASE ==========');
        print('User ID: $userId');
        print('Nama Staff: $namaStaff');
        print('Email: $email');
        print('Jabatan: $jabatan');
      }

      // Step 1: Create Firebase Authentication account for staff
      UserCredential? userCredential;
      try {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (kDebugMode) {
          print('Firebase Auth account created: ${userCredential.user?.uid}');
        }
      } catch (firebaseError) {
        if (kDebugMode) {
          print('Firebase Auth error: $firebaseError');
        }
        // If Firebase account creation fails, don't proceed
        return false;
      }

      // Step 2: Store staff data in Firebase Firestore
      try {
        await FirebaseFirestore.instance
            .collection('staff')
            .doc(userCredential.user!.uid)
            .set({
          'user_id': userId, // Admin's userId who created this staff
          'nama_staff': namaStaff,
          'email': email,
          'jabatan': jabatan,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'staff',
        });

        if (kDebugMode) {
          print('Staff data saved to Firestore');
        }
      } catch (firestoreError) {
        if (kDebugMode) {
          print('Firestore error: $firestoreError');
        }
        // If Firestore fails, delete the auth account
        await userCredential.user?.delete();
        return false;
      }

      // Step 3: Add staff to GoCloud database
      final uri = '$_baseUrl/insert/';

      final body = {
        'token': token,
        'project': project,
        'collection': _collection,
        'appid': appid,
        'user_id': userId,
        'nama_staff': namaStaff,
        'email': email,
        'kata_sandi': password,
        'jabatan': jabatan,
        'foto': fotoProfile ?? '',
        'firebase_uid': userCredential.user!.uid, // Store Firebase UID
      };

      final response = await http.post(
        Uri.parse(uri),
        body: body,
      );

      if (kDebugMode) {
        print('GoCloud Response status: ${response.statusCode}');
        print('GoCloud Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Staff added successfully to all databases');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to add staff to GoCloud. Status: ${response.statusCode}');
        }
        // Rollback: Delete Firebase data if GoCloud fails
        await FirebaseFirestore.instance
            .collection('staff')
            .doc(userCredential.user!.uid)
            .delete();
        await userCredential.user?.delete();
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
        print('========== DELETING STAFF FROM ALL DATABASES ==========');
        print('Staff ID: $staffId');
      }

      // Step 1: Get staff data first to retrieve email for Firebase deletion
      final uri = '$_baseUrl/select/';
      final getResponse = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          '_id': staffId,
        },
      );

      String? staffEmail;
      String? firebaseUid;

      if (getResponse.statusCode == 200 && getResponse.body.isNotEmpty) {
        try {
          final responseData = json.decode(getResponse.body);
          Map<String, dynamic>? staffData;

          if (responseData is List && responseData.isNotEmpty) {
            staffData = Map<String, dynamic>.from(responseData.first);
          } else if (responseData is Map) {
            staffData = Map<String, dynamic>.from(responseData);
          }

          if (staffData != null) {
            staffEmail = staffData['email'];
            firebaseUid = staffData['firebase_uid'];
          }
        } catch (e) {
          if (kDebugMode) print('Error parsing staff data: $e');
        }
      }

      // Step 2: Delete from GoCloud
      final deleteUri = '$_baseUrl/delete/';
      final response = await http.post(
        Uri.parse(deleteUri),
        body: {
          'token': token,
          'project': project,
          'collection': _collection,
          'appid': appid,
          '_id': staffId,
        },
      );

      if (kDebugMode) {
        print('GoCloud Response status: ${response.statusCode}');
        print('GoCloud Response body: ${response.body}');
      }

      bool goCloudSuccess = response.statusCode == 200;

      // Step 3: Delete from Firebase Firestore (using email or firebase_uid)
      if (staffEmail != null || firebaseUid != null) {
        try {
          if (firebaseUid != null) {
            // Delete using Firebase UID if available
            await FirebaseFirestore.instance
                .collection('staff')
                .doc(firebaseUid)
                .delete();
            if (kDebugMode) print('Deleted from Firestore using UID');
          } else if (staffEmail != null) {
            // Fallback: Search by email and delete
            final querySnapshot = await FirebaseFirestore.instance
                .collection('staff')
                .where('email', isEqualTo: staffEmail)
                .get();

            for (var doc in querySnapshot.docs) {
              await doc.reference.delete();
            }
            if (kDebugMode) print('Deleted from Firestore using email');
          }
        } catch (firestoreError) {
          if (kDebugMode) print('Firestore deletion error: $firestoreError');
        }

        // Note: We cannot delete from Firebase Auth without the user being logged in
        // The admin cannot delete another user's auth account directly
        // This would require Firebase Admin SDK or Cloud Functions
        if (kDebugMode) {
          print('Note: Firebase Auth account should be disabled/deleted via Admin SDK');
        }
      }

      if (goCloudSuccess) {
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

      // Step 1: Authenticate with Firebase
      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (kDebugMode) {
          print('Firebase Authentication successful: ${userCredential.user?.uid}');
        }
      } catch (authError) {
        if (kDebugMode) {
          print('Firebase Authentication failed: $authError');
        }
        return null;
      }

      // Step 2: Get staff data from Firestore
      try {
        final staffDoc = await FirebaseFirestore.instance
            .collection('staff')
            .doc(userCredential.user!.uid)
            .get();

        if (!staffDoc.exists) {
          if (kDebugMode) {
            print('Staff document not found in Firestore');
          }
          return null;
        }

        final staffData = staffDoc.data()!;

        // Step 3: Also get data from GoCloud to ensure consistency
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
          print('GoCloud Response status: ${response.statusCode}');
        }

        // Create StaffModel from Firestore data (primary) with GoCloud as fallback
        String staffId = userCredential.user!.uid;
        String userId = staffData['user_id'] ?? '';
        String nama = staffData['nama_staff'] ?? '';
        String jabatan = staffData['jabatan'] ?? '';

        // Try to get additional data from GoCloud if available
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          try {
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

            if (dataList.isNotEmpty) {
              final goCloudData = Map<String, dynamic>.from(dataList.first);
              staffId = goCloudData['_id'] ?? goCloudData['id'] ?? staffId;
              // Use GoCloud data if Firestore is missing some fields
              if (nama.isEmpty) nama = goCloudData['nama_staff'] ?? '';
              if (jabatan.isEmpty) jabatan = goCloudData['jabatan'] ?? '';
              if (userId.isEmpty) userId = goCloudData['user_id'] ?? '';
            }
          } catch (e) {
            if (kDebugMode) print('Error parsing GoCloud response: $e');
          }
        }

        final staff = StaffModel(
          id: staffId,
          nama_staff: nama,
          email: email,
          kata_sandi: '', // Don't expose password
          jabatan: jabatan,
          foto: '', // No photo needed
          user_id: userId,
        );

        if (kDebugMode) {
          print('Staff authenticated successfully');
          print('Staff Name: ${staff.nama_staff}');
          print('Jabatan: ${staff.jabatan}');
        }

        return staff;
      } catch (firestoreError) {
        if (kDebugMode) {
          print('Firestore error: $firestoreError');
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

