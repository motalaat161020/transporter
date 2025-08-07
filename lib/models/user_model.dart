import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { rider, driver }

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? profileImage;
  final UserType userType;
  final double balance;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, dynamic>? additionalData;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.profileImage,
    required this.userType,
    this.balance = 0.0,
    required this.createdAt,
    this.isActive = true,
    this.additionalData,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImage'],
      userType: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${map['userType']}',
        orElse: () => UserType.rider,
      ),
      balance: (map['balance'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      additionalData: map['additionalData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'profileImage': profileImage,
      'userType': userType.name,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'additionalData': additionalData,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? profileImage,
    UserType? userType,
    double? balance,
    DateTime? createdAt,
    bool? isActive,
    Map<String, dynamic>? additionalData,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      userType: userType ?? this.userType,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

class DriverModel extends UserModel {
  final String carType;
  final String carNumber;
  final String licenseNumber;
  final String? carImage;
  final bool isOnline;
  final double? currentLat;
  final double? currentLng;

  DriverModel({
    required String id,
    required String name,
    required String phone,
    required String email,
    String? profileImage,
    double balance = 0.0,
    required DateTime createdAt,
    bool isActive = true,
    required this.carType,
    required this.carNumber,
    required this.licenseNumber,
    this.carImage,
    this.isOnline = false,
    this.currentLat,
    this.currentLng,
  }) : super(
          id: id,
          name: name,
          phone: phone,
          email: email,
          profileImage: profileImage,
          userType: UserType.driver,
          balance: balance,
          createdAt: createdAt,
          isActive: isActive,
          additionalData: {
            'carType': carType,
            'carNumber': carNumber,
            'licenseNumber': licenseNumber,
            'carImage': carImage,
            'isOnline': isOnline,
            'currentLat': currentLat,
            'currentLng': currentLng,
          },
        );

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    final user = UserModel.fromMap(map);
    return DriverModel(
      id: user.id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      profileImage: user.profileImage,
      balance: user.balance,
      createdAt: user.createdAt,
      isActive: user.isActive,
      carType: map['additionalData']?['carType'] ?? '',
      carNumber: map['additionalData']?['carNumber'] ?? '',
      licenseNumber: map['additionalData']?['licenseNumber'] ?? '',
      carImage: map['additionalData']?['carImage'],
      isOnline: map['additionalData']?['isOnline'] ?? false,
      currentLat: map['additionalData']?['currentLat']?.toDouble(),
      currentLng: map['additionalData']?['currentLng']?.toDouble(),
    );
  }
}