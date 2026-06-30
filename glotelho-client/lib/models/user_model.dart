class UserModel {
  final int id;
  final String lastName;
  final String firstName;
  final String email;
  final String phone;
  final String role;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.role,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      lastName: json['last_name'],
      firstName: json['first_name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      fcmToken: json['fcm_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'last_name': lastName,
      'first_name': firstName,
      'email': email,
      'phone': phone,
      'role': role,
      'fcm_token': fcmToken,
    };
  }
}