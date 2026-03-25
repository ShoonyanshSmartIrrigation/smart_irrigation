import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String _generatedOtp = "";

  String get generatedOtp => _generatedOtp;

  bool validateUserInput({required String name, required String phone, required String email}) {
    if (name.isEmpty) return false;
    if (phone.isEmpty || phone.length < 10) return false;
    if (email.isEmpty || !email.contains("@")) return false;
    return true;
  }

  bool validateOtp(String otp) {
    if (otp.isEmpty) return false;
    if (otp.length != 6) return false;
    return true;
  }

  String generateOtp() {
    Random random = Random();
    _generatedOtp = (100000 + random.nextInt(900000)).toString();
    return _generatedOtp;
  }

  Future<bool> verifyOtp(String otp, {required String name, required String email, required String phone}) async {
    if (otp == _generatedOtp) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', name);
      await prefs.setString('userEmail', email);
      await prefs.setString('userPhone', phone);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, String?>> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'userName': prefs.getString('userName'),
      'userEmail': prefs.getString('userEmail'),
      'userPhone': prefs.getString('userPhone'),
    };
  }
}
