import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up with Email and Password
  Future<User?> signUpWithEmail(String email, String password, String name, String phone) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Save user data to SharedPreferences for local use
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', name);
        await prefs.setString('userEmail', email);
        await prefs.setString('userPhone', phone);
        
        // Update Firebase Display Name
        await user.updateDisplayName(name);
      }
      return user;
    } catch (e) {
      print("Error in Signup: ${e.toString()}");
      return null;
    }
  }

  // Login with Email and Password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', user.displayName ?? "User");
        await prefs.setString('userEmail', user.email ?? "");
      }
      return user;
    } catch (e) {
      print("Error in Login: ${e.toString()}");
      return null;
    }
  }

  // Send Password Reset Email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print("Error in Password Reset: ${e.toString()}");
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
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
