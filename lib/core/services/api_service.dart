import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants/api_constants.dart';
import '../models/auth_response_model.dart';
import '../models/staff_model.dart';
import '../models/attendance_model.dart';
import '../models/report_model.dart';
import '../models/cashbook_model.dart';
import '../models/subscription_model.dart';
import '../services/storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Connectivity _connectivity = Connectivity();

  Future<bool> _checkInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> _handleRequest(
    Future<http.Response> Function() request,
  ) async {
    // Check internet connection
    final hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      throw ApiException(
        message: 'No internet connection',
        statusCode: 0,
        type: ApiExceptionType.noInternet,
      );
    }

    try {
      final response = await request();
      return response;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
        type: ApiExceptionType.networkError,
      );
    }
  }

  // Auth APIs
  Future<AuthResponseModel> signup({
    required String name,
    required String email,
    required String mobile,
    required String businessName,
    required int staffSize,
    required String password,
  }) async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/auth/register'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'mobile': mobile,
          'business_name': businessName,
          'staff_size': staffSize,
          'password': password,
        }),
      );
    });

    return _handleResponse<AuthResponseModel>(
      response,
      (json) => AuthResponseModel.fromJson(json),
    );
  }

  Future<AuthResponseModel> login({
    required String mobile,
    required String password,
  }) async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/auth/login'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'mobile': mobile,
          'password': password,
        }),
      );
    });

    return _handleResponse<AuthResponseModel>(
      response,
      (json) => AuthResponseModel.fromJson(json),
    );
  }

  Future<void> logout() async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/auth/logout'),
        headers: await _getHeaders(includeAuth: true),
      );
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await StorageService.clearUser();
    } else {
      _handleResponse<Map<String, dynamic>>(
        response,
        (json) => json,
      );
    }
  }

  Future<void> deleteAccount() async {
    final response = await _handleRequest(() async {
      return await http.delete(
        Uri.parse('${ApiConstants.basePath}/auth/delete-account'),
        headers: await _getHeaders(includeAuth: true),
      );
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await StorageService.clearUser();
    } else {
      final body = jsonDecode(response.body);
      throw ApiException(
        message: body['message'] ?? 'Failed to delete account',
        statusCode: response.statusCode,
        type: ApiExceptionType.serverError,
      );
    }
  }

  Future<AuthResponseModel> getCurrentUser() async {
    final response = await _handleRequest(() async {
      return await http.get(
        Uri.parse('${ApiConstants.basePath}/auth/me'),
        headers: await _getHeaders(includeAuth: true),
      );
    });

    return _handleResponse<AuthResponseModel>(
      response,
      (json) => AuthResponseModel.fromJson(json),
    );
  }

  // Staff APIs
  Future<List<StaffModel>> getStaffList() async {
    final response = await _handleRequest(() async {
      return await http.get(
        Uri.parse('${ApiConstants.basePath}/staff'),
        headers: await _getHeaders(includeAuth: true),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(
      response,
      (json) => json,
    );

    final staffList = json['data']?['staff'] as List<dynamic>?;
    if (staffList == null) {
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        type: ApiExceptionType.parseError,
      );
    }

    return staffList
        .map((item) => StaffModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StaffModel> createStaff({
    required String name,
    required String phoneNumber,
    required String salaryType,
    required double salaryAmount,
    double overtimeCharges = 0.0,
  }) async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/staff'),
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode({
          'name': name,
          'phone_number': phoneNumber,
          'salary_type': salaryType,
          'salary_amount': salaryAmount,
          'overtime_charges': overtimeCharges,
        }),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(
      response,
      (json) => json,
    );

    final staffData = json['data']?['staff'] as Map<String, dynamic>?;
    if (staffData == null) {
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        type: ApiExceptionType.parseError,
      );
    }

    return StaffModel.fromJson(staffData);
  }

  Future<StaffModel> updateStaff({
    required int id,
    String? name,
    String? phoneNumber,
    String? salaryType,
    double? salaryAmount,
    double? overtimeCharges,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (salaryType != null) body['salary_type'] = salaryType;
    if (salaryAmount != null) body['salary_amount'] = salaryAmount;
    if (overtimeCharges != null) body['overtime_charges'] = overtimeCharges;

    final response = await _handleRequest(() async {
      return await http.put(
        Uri.parse('${ApiConstants.basePath}/staff/$id'),
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(
      response,
      (json) => json,
    );

    final staffData = json['data']?['staff'] as Map<String, dynamic>?;
    if (staffData == null) {
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        type: ApiExceptionType.parseError,
      );
    }

    return StaffModel.fromJson(staffData);
  }

  Future<void> deleteStaff(int id) async {
    await _handleRequest(() async {
      return await http.delete(
        Uri.parse('${ApiConstants.basePath}/staff/$id'),
        headers: await _getHeaders(includeAuth: true),
      );
    });
  }

  // Attendance APIs
  Future<AttendanceModel> markAttendance({
    required int staffId,
    required DateTime date,
    required String status, // 'present', 'half_day', 'absent', 'off'
    String? inTime,
    String? outTime,
    double? workedHours,
    double? payMultiplier,
  }) async {
    final body = <String, dynamic>{
      'staff_id': staffId,
      'date': date.toIso8601String().split('T')[0],
      'status': status,
    };

    if ((status == 'present' || status == 'half_day') && inTime != null) {
      body['in_time'] = inTime;
    }
    if (outTime != null) {
      body['out_time'] = outTime;
    }
    if (workedHours != null && workedHours > 0) {
      body['worked_hours'] = workedHours;
    }
    if (payMultiplier != null) {
      body['pay_multiplier'] = payMultiplier;
    }

    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/attendance/mark'),
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(
      response,
      (json) => json,
    );

    final attendanceData = json['data']?['attendance'] as Map<String, dynamic>?;
    if (attendanceData == null) {
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        type: ApiExceptionType.parseError,
      );
    }

    // Convert status to match our model format
    final statusValue = attendanceData['status'] as String? ?? '';
    String displayStatus = statusValue;
    if (statusValue == 'present' && ((attendanceData['overtime_hours'] as num?)?.toDouble() ?? 0) > 0) {
      displayStatus = 'OT';
    } else if (statusValue == 'present') {
      displayStatus = 'P';
    } else if (statusValue == 'half_day') {
      displayStatus = 'HD';
    } else if (statusValue == 'absent') {
      displayStatus = 'A';
    } else if (statusValue == 'off') {
      displayStatus = 'Off';
    }

    return AttendanceModel(
      id: attendanceData['id'] as int?,
      staffId: staffId, // Use parameter instead of json
      date: DateTime.parse(attendanceData['date'] as String),
      status: displayStatus,
      inTime: attendanceData['in_time'] as String?,
      outTime: attendanceData['out_time'] as String?,
      overtimeHours: (attendanceData['overtime_hours'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (attendanceData['advance_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<void> clearAttendance({
    required int staffId,
    required DateTime date,
  }) async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/attendance/clear'),
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode({
          'staff_id': staffId,
          'date': date.toIso8601String().split('T')[0],
        }),
      );
    });
    _handleResponse<Map<String, dynamic>>(response, (json) => json);
  }

  Future<AttendanceModel> markOT({
    required int staffId,
    required DateTime date,
    required double overtimeHours,
  }) async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/attendance/mark-ot'),
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode({
          'staff_id': staffId,
          'date': date.toIso8601String().split('T')[0],
          'overtime_hours': overtimeHours,
        }),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(
      response,
      (json) => json,
    );

    final attendanceData = json['data']?['attendance'] as Map<String, dynamic>?;
    if (attendanceData == null) {
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        type: ApiExceptionType.parseError,
      );
    }

    return AttendanceModel(
      id: attendanceData['id'] as int?,
      staffId: attendanceData['staff_id'] as int,
      date: DateTime.parse(attendanceData['date'] as String),
      status: 'OT',
      inTime: attendanceData['in_time'] as String?,
      outTime: attendanceData['out_time'] as String?,
      overtimeHours: (attendanceData['overtime_hours'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (attendanceData['advance_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<AttendanceModel> markAdvance({
    required int staffId,
    required DateTime date,
    required double amount,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'staff_id': staffId,
      'date': date.toIso8601String().split('T')[0],
      'amount': amount,
    };
    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes.trim();
    }

    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/attendance/advance'),
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(
      response,
      (json) => json,
    );

    final attendanceData = json['data']?['attendance'] as Map<String, dynamic>?;
    if (attendanceData == null) {
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        type: ApiExceptionType.parseError,
      );
    }

    final statusValue = attendanceData['status'] as String? ?? '';
    String displayStatus = statusValue;
    if (statusValue == 'present' && ((attendanceData['overtime_hours'] as num?)?.toDouble() ?? 0) > 0) {
      displayStatus = 'OT';
    } else if (statusValue == 'present') {
      displayStatus = 'P';
    } else if (statusValue == 'half_day') {
      displayStatus = 'HD';
    } else if (statusValue == 'absent') {
      displayStatus = 'A';
    } else if (statusValue == 'off') {
      displayStatus = 'Off';
    }

    return AttendanceModel(
      id: attendanceData['id'] as int?,
      staffId: staffId,
      date: DateTime.parse(attendanceData['date'] as String),
      status: displayStatus,
      inTime: attendanceData['in_time'] as String?,
      outTime: attendanceData['out_time'] as String?,
      overtimeHours: (attendanceData['overtime_hours'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (attendanceData['advance_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<void> updateAdvance(int attendanceId, double amount) async {
    await _handleRequest(() async {
      return await http.put(
        Uri.parse('${ApiConstants.basePath}/attendance/advance/$attendanceId'),
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode({'amount': amount}),
      );
    });
  }

  Future<void> clearAdvance(int attendanceId) async {
    await _handleRequest(() async {
      return await http.delete(
        Uri.parse('${ApiConstants.basePath}/attendance/advance/$attendanceId'),
        headers: await _getHeaders(includeAuth: true),
      );
    });
  }

  Future<Map<String, dynamic>> getAttendance({
    required int staffId,
    int? month,
    int? year,
  }) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse('${ApiConstants.basePath}/attendance/staff/$staffId')
        .replace(queryParameters: queryParams);

    final response = await _handleRequest(() async {
      return await http.get(
        uri,
        headers: await _getHeaders(includeAuth: true),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(
      response,
      (json) => json,
    );

    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        type: ApiExceptionType.parseError,
      );
    }

    final summaryData = data['summary'] as Map<String, dynamic>?;
    if (summaryData == null) {
      throw ApiException(
        message: 'Summary data not found in response',
        statusCode: response.statusCode,
        type: ApiExceptionType.parseError,
      );
    }
    final summary = AttendanceSummaryModel.fromJson(summaryData);

    final attendancesList = data['attendances'] as List<dynamic>? ?? [];
    final attendances = attendancesList.map((item) {
      final json = item as Map<String, dynamic>;
      // Backend already converts status to 'P', 'A', 'OT', 'Off' format, but handle both cases
      final statusValue = json['status'] as String? ?? '';
      String displayStatus = statusValue;
      
      // Handle if backend sends raw status values (present, half_day, absent, off)
      if (statusValue == 'present' && ((json['overtime_hours'] as num?)?.toDouble() ?? 0) > 0) {
        displayStatus = 'OT';
      } else if (statusValue == 'present') {
        displayStatus = 'P';
      } else if (statusValue == 'half_day') {
        displayStatus = 'HD';
      } else if (statusValue == 'absent') {
        displayStatus = 'A';
      } else if (statusValue == 'off') {
        displayStatus = 'Off';
      }
      // If already in display format (P, HD, A, OT, Off), keep it as is
      
      return AttendanceModel(
        id: json['id'] as int?,
        staffId: staffId, // Use staffId from method parameter
        date: DateTime.parse(json['date'] as String),
        status: displayStatus,
        inTime: json['in_time'] as String?,
        outTime: json['out_time'] as String?,
        overtimeHours: (json['overtime_hours'] as num?)?.toDouble() ?? 0.0,
        advanceAmount: (json['advance_amount'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return {
      'summary': summary,
      'attendances': attendances,
    };
  }

  /// Get labor report for a staff member
  Future<LaborReportModel> getLaborReport({
    required int staffId,
    int? month,
    int? year,
  }) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse('${ApiConstants.basePath}/report/labor/$staffId')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await _handleRequest(() async {
      return await http.get(
        uri,
        headers: await _getHeaders(includeAuth: true),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(
      response,
      (json) => json,
    );

    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        type: ApiExceptionType.parseError,
      );
    }

    return LaborReportModel.fromJson(data);
  }

  // Cashbook APIs (income, expenses; advances appear as expenses automatically)
  Future<CashbookOverviewModel> getCashbookOverview({
    required int month,
    required int year,
  }) async {
    final uri = Uri.parse('${ApiConstants.basePath}/cashbook/overview').replace(
      queryParameters: {'month': month.toString(), 'year': year.toString()},
    );
    final response = await _handleRequest(() async {
      return await http.get(
        uri,
        headers: await _getHeaders(includeAuth: true),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(response, (json) => json);
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        type: ApiExceptionType.parseError,
      );
    }
    return CashbookOverviewModel.fromJson(data);
  }

  Future<List<CashbookTransactionModel>> getCashbookTransactions({
    required int month,
    required int year,
  }) async {
    final uri = Uri.parse('${ApiConstants.basePath}/cashbook/transactions').replace(
      queryParameters: {'month': month.toString(), 'year': year.toString()},
    );
    final response = await _handleRequest(() async {
      return await http.get(
        uri,
        headers: await _getHeaders(includeAuth: true),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(response, (json) => json);
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        type: ApiExceptionType.parseError,
      );
    }
    final list = data['transactions'] as List<dynamic>? ?? [];
    return list
        .map((e) => CashbookTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addCashbookIncome({
    required DateTime date,
    required double amount,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'date': date.toIso8601String().split('T')[0],
      'amount': amount,
    };
    if (description != null && description.isNotEmpty) body['description'] = description;

    await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/cashbook/income'),
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );
    });
  }

  Future<void> updateCashbookIncome({
    required int id,
    required DateTime date,
    required double amount,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'date': date.toIso8601String().split('T')[0],
      'amount': amount,
    };
    if (description != null && description.isNotEmpty) body['description'] = description;

    await _handleRequest(() async {
      return await http.put(
        Uri.parse('${ApiConstants.basePath}/cashbook/income/$id'),
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );
    });
  }

  Future<void> deleteCashbookIncome(int id) async {
    await _handleRequest(() async {
      return await http.delete(
        Uri.parse('${ApiConstants.basePath}/cashbook/income/$id'),
        headers: await _getHeaders(includeAuth: true),
      );
    });
  }

  Future<void> addCashbookExpense({
    required DateTime date,
    required double amount,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'date': date.toIso8601String().split('T')[0],
      'amount': amount,
    };
    if (description != null && description.isNotEmpty) body['description'] = description;

    await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/cashbook/expense'),
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );
    });
  }

  Future<void> updateCashbookExpense({
    required int id,
    required DateTime date,
    required double amount,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'date': date.toIso8601String().split('T')[0],
      'amount': amount,
    };
    if (description != null && description.isNotEmpty) body['description'] = description;

    await _handleRequest(() async {
      return await http.put(
        Uri.parse('${ApiConstants.basePath}/cashbook/expense/$id'),
        headers: await _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );
    });
  }

  Future<void> deleteCashbookExpense(int id) async {
    await _handleRequest(() async {
      return await http.delete(
        Uri.parse('${ApiConstants.basePath}/cashbook/expense/$id'),
        headers: await _getHeaders(includeAuth: true),
      );
    });
  }

  // Subscription APIs
  Future<SubscriptionStatusModel> getSubscriptionStatus() async {
    final response = await _handleRequest(() async {
      return await http.get(
        Uri.parse('${ApiConstants.basePath}/subscription/status'),
        headers: await _getHeaders(includeAuth: true),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(response, (json) => json);
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    return SubscriptionStatusModel.fromJson(data);
  }

  Future<SubscriptionCreateResponse> createSubscription() async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/subscription/create'),
        headers: await _getHeaders(includeAuth: true),
      );
    });

    final json = _handleResponse<Map<String, dynamic>>(response, (json) => json);
    return SubscriptionCreateResponse.fromJson(json);
  }

  Future<void> cancelSubscription() async {
    await _handleRequest(() async {
      return await http.post(
        Uri.parse('${ApiConstants.basePath}/subscription/cancel'),
        headers: await _getHeaders(includeAuth: true),
      );
    });
  }

  T _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return fromJson(json);
      } catch (e) {
        throw ApiException(
          message: 'Invalid response format',
          statusCode: statusCode,
          type: ApiExceptionType.parseError,
        );
      }
    } else if (statusCode == 401) {
      throw ApiException(
        message: 'Unauthorized. Please login again.',
        statusCode: statusCode,
        type: ApiExceptionType.unauthorized,
      );
    } else if (statusCode == 422) {
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final errors = json['errors'] as Map<String, dynamic>?;
        final message = errors?.values.first?.first?.toString() ?? 
                       json['message']?.toString() ?? 
                       'Validation error';
        throw ApiException(
          message: message,
          statusCode: statusCode,
          type: ApiExceptionType.validationError,
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          message: 'Validation error',
          statusCode: statusCode,
          type: ApiExceptionType.validationError,
        );
      }
    } else if (statusCode >= 500) {
      throw ApiException(
        message: 'Server error. Please try again later.',
        statusCode: statusCode,
        type: ApiExceptionType.serverError,
      );
    } else {
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final message = json['message']?.toString() ?? 'Request failed';
        throw ApiException(
          message: message,
          statusCode: statusCode,
          type: ApiExceptionType.unknown,
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          message: 'Request failed',
          statusCode: statusCode,
          type: ApiExceptionType.unknown,
        );
      }
    }
  }

}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final ApiExceptionType type;

  ApiException({
    required this.message,
    required this.statusCode,
    required this.type,
  });

  @override
  String toString() => message;
}

enum ApiExceptionType {
  noInternet,
  networkError,
  serverError,
  unauthorized,
  validationError,
  parseError,
  unknown,
}
