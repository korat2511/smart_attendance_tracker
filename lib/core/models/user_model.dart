class UserModel {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String businessName;
  final int staffSize;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.businessName,
    required this.staffSize,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String,
      businessName: json['business_name'] as String,
      staffSize: json['staff_size'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'business_name': businessName,
      'staff_size': staffSize,
    };
  }
}
