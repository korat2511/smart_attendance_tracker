class StaffModel {
  final int? id;
  final String name;
  final String phoneNumber;
  final String salaryType; // hourly, daily, weekly, monthly
  final double salaryAmount;
  final double overtimeCharges;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StaffModel({
    this.id,
    required this.name,
    required this.phoneNumber,
    required this.salaryType,
    required this.salaryAmount,
    this.overtimeCharges = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      salaryType: json['salary_type'] as String,
      salaryAmount: (json['salary_amount'] as num).toDouble(),
      overtimeCharges: (json['overtime_charges'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'salary_type': salaryType,
      'salary_amount': salaryAmount,
      'overtime_charges': overtimeCharges,
    };
  }

  StaffModel copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    String? salaryType,
    double? salaryAmount,
    double? overtimeCharges,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      salaryType: salaryType ?? this.salaryType,
      salaryAmount: salaryAmount ?? this.salaryAmount,
      overtimeCharges: overtimeCharges ?? this.overtimeCharges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
