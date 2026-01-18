//lib/model/user_model.dart
class UserModel {
  final String id;
  final String username;
  final String email;
  final String password;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.password
  });

  factory UserModel.fromJson(Map data) {
    return UserModel(
        id: data['_id'],
        username: data['username'],
        email: data['email'],
        password: data['password']
    );
  }
}