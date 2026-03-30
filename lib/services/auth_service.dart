import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  // 11. Loading State
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 6. Auth State Listener
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 10. Internet Handling Helper
  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw AuthException("No internet connection. Please check your network.");
    }
  }

  // 13. Duplicate Code Fix: Centralized User Data Storage
  Future<void> _saveUserData({
    required String name,
    required String email,
    String? phone,
  }) async {
    await _prefs.setBool('isLoggedIn', true);
    await _secureStorage.write(key: 'userName', value: name);
    await _secureStorage.write(key: 'userEmail', value: email);
    if (phone != null) {
      await _secureStorage.write(key: 'userPhone', value: phone);
    }
  }

  // 4. Firebase Exception Handling Helper
  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No user found with this email.";
      case 'wrong-password':
        return "Incorrect password. Please try again.";
      case 'email-already-in-use':
        return "This email is already registered.";
      case 'invalid-email':
        return "The email address is not valid.";
      case 'weak-password':
        return "The password is too weak.";
      case 'user-disabled':
        return "This user has been disabled.";
      case 'too-many-requests':
        return "Too many attempts. Please try again later.";
      case 'operation-not-allowed':
        return "This operation is not allowed.";
      default:
        return e.message ?? "Authentication failed. Please try again.";
    }
  }

  // Sign Up with Email and Password
  Future<User?> signUpWithEmail(String email, String password, String name, String phone) async {
    await _checkConnectivity();
    _isLoading = true;
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(name);
        await _saveUserData(name: name, email: email, phone: phone);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseError(e));
    } catch (e) {
      throw AuthException("An unexpected error occurred during signup.");
    } finally {
      _isLoading = false;
    }
  }

  // Login with Email and Password
  Future<User?> loginWithEmail(String email, String password) async {
    await _checkConnectivity();
    _isLoading = true;
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _saveUserData(
          name: user.displayName ?? "User",
          email: user.email ?? "",
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseError(e));
    } catch (e) {
      throw AuthException("An unexpected error occurred during login.");
    } finally {
      _isLoading = false;
    }
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    await _checkConnectivity();
    _isLoading = true;
    try {
      const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', 
          defaultValue: '977787660840-bitbnld9abh2br1ioq2ach0jndcfsa2c.apps.googleusercontent.com');
      await _googleSignIn.initialize(
        serverClientId: googleClientId,
      );

      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final GoogleSignInClientAuthorization? clientAuth = 
          await googleUser.authorizationClient.authorizationForScopes(['email', 'profile']);

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth?.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user != null) {
        await _saveUserData(
          name: user.displayName ?? "User",
          email: user.email ?? "",
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseError(e));
    } catch (e) {
      throw AuthException("Google Sign-In failed.");
    } finally {
      _isLoading = false;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    await _checkConnectivity();
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseError(e));
    } catch (e) {
      throw AuthException("An unexpected error occurred.");
    }
  }

  //------------------------------------------- Logout Functionality--------------------------------------
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      
      // 9. Logout Fully Safe: Only remove auth-related keys
      await _prefs.remove('isLoggedIn');
      await _secureStorage.deleteAll();
    } catch (e) {
      throw AuthException("Logout failed.");
    }
  }

  Future<Map<String, String?>> getUserData() async {
    return {
      'userName': await _secureStorage.read(key: 'userName'),
      'userEmail': await _secureStorage.read(key: 'userEmail'),
      'userPhone': await _secureStorage.read(key: 'userPhone'),
    };
  }
}
