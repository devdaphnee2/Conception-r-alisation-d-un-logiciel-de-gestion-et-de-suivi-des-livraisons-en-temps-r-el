class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String? address;
  final String? avatarUrl;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.address,
    this.avatarUrl,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:        json['id'],
      fullName:  json['full_name'] ?? '',
      email:     json['email']     ?? '',
      phone:     json['phone']     ?? '',
      address:   json['address'],
      avatarUrl: json['avatar_url'],
      fcmToken:  json['fcm_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':        id,
      'full_name': fullName,
      'email':     email,
      'phone':     phone,
      'address':   address,
      'avatar_url': avatarUrl,
      'fcm_token': fcmToken,
    };
  }
}
