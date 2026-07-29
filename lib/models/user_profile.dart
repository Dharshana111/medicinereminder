import 'dart:convert';

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String bloodGroup;
  final String gender;
  final int age;
  final double weight;
  final double height;
  final DateTime dob;
  final String? emergencyContact;
  final String? allergies;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.bloodGroup,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.dob,
    this.emergencyContact,
    this.allergies,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? bloodGroup,
    String? gender,
    int? age,
    double? weight,
    double? height,
    DateTime? dob,
    String? emergencyContact,
    String? allergies,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      dob: dob ?? this.dob,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      allergies: allergies ?? this.allergies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'bloodGroup': bloodGroup,
      'gender': gender,
      'age': age,
      'weight': weight,
      'height': height,
      'dob': dob.toIso8601String(),
      'emergencyContact': emergencyContact,
      'allergies': allergies,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      bloodGroup: json['bloodGroup'] as String,
      gender: json['gender'] as String,
      age: json['age'] as int,
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      dob: DateTime.parse(json['dob'] as String),
      emergencyContact: json['emergencyContact'] as String?,
      allergies: json['allergies'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserProfile.fromJsonString(String jsonString) {
    return UserProfile.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
