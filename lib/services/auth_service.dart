import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Sign Up with Email and Password
  Future<User?> signUpWithEmail(String email, String password, String name, String phone) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', name);
        await prefs.setString('userEmail', email);
        await prefs.setString('userPhone', phone);
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

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Initialize (Required for version 7.x)
      await _googleSignIn.initialize(
        serverClientId: '977787660840-bitbnld9abh2br1ioq2ach0jndcfsa2c.apps.googleusercontent.com',
      );

      // 2. Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      
      if (googleUser == null) {
        print("Google Sign-In: User canceled the flow.");
        return null;
      }

      // 3. Obtain the auth details (idToken)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. Retrieve Access Token separately if needed (New in 7.x)
      final GoogleSignInClientAuthorization? clientAuth = 
          await googleUser.authorizationClient.authorizationForScopes(['email', 'profile']);

      // 5. Create a credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth?.accessToken, // Use the new clientAuth object
        idToken: googleAuth.idToken,
      );

      // 6. Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', user.displayName ?? "User");
        await prefs.setString('userEmail', user.email ?? "");
      }

      return user;
    } on GoogleSignInException catch (e) {
      print("Google Sign-In Exception: ${e.code} - ${e.description}");
      return null;
    } catch (e) {
      print("General Google Sign-In Error: $e");
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


//---------------------------------------------Logout Functionality------------------------------------------------------------
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
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
