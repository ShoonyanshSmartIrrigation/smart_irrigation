import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Routes/app_Routes.dart';
import '../Widgets/build_header.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleSignUp() async {
    String name = nameController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // 🔴 3. Weak Validation Improved
    if (name.length < 3) {
      showToast("Name too short");
      return;
    }
    if (phone.length != 10) {
      showToast("Enter valid 10-digit phone number");
      return;
    }
    if (!email.contains("@") || !email.contains(".")) {
      showToast("Enter valid email");
      return;
    }
    if (password.length < 6) {
      showToast("Password must be at least 6 characters");
      return;
    }

    // 🔴 4. No Internet Handling
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      showToast("No internet connection");
      return;
    }

    setState(() => _isLoading = true);

    // 🔴 2. Error Handling Added
    try {
      User? user = await _authService.signUpWithEmail(email, password, name, phone);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        showToast("Signup Successful!");
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        showToast("Signup Failed. Please check your details.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showToast("Something went wrong. Please try again.");
    }
  }

  void handleGoogleSignIn() async {
    // 🔴 4. No Internet Handling
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      showToast("No internet connection");
      return;
    }

    // 🔴 5. Google Sign-In With Loading State
    setState(() => _isLoading = true);

    try {
      User? user = await _authService.signInWithGoogle();
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        showToast("Logged in with Google!");
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        showToast("Google Sign-In failed.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showToast("Google Sign-In error occurred.");
    }
  }

  void showToast(String msg) {
    // 🔴 6. SnackBar Stacking Issue Fixed
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      // 🔴 9. Keyboard Handling
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            BuildHeader(
              height: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_rounded, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    "Start managing your irrigation smarter",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔴 7. Autofill Support Added
                  _buildTextField(nameController, "Full Name", Icons.person_outline, autofillHints: [AutofillHints.name]),
                  const SizedBox(height: 16),
                  _buildTextField(phoneController, "Phone Number", Icons.phone_android_outlined, inputType: TextInputType.phone, autofillHints: [AutofillHints.telephoneNumber]),
                  const SizedBox(height: 16),
                  _buildTextField(emailController, "Email Address", Icons.email_outlined, inputType: TextInputType.emailAddress, autofillHints: [AutofillHints.email]),
                  const SizedBox(height: 16),
                  _buildTextField(
                    passwordController, 
                    "Password", 
                    Icons.lock_outline_rounded, 
                    isPassword: true,
                    obscureText: _obscurePassword,
                    autofillHints: [AutofillHints.password],
                    onTogglePassword: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    }
                  ),

                  const SizedBox(height: 30),

                  _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                  : ElevatedButton(
                    // 🔴 8. Button Disable During Loading
                    onPressed: _isLoading ? null : handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                    ),
                    child: const Text(
                      "SIGN UP", 
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)
                    ),
                  ),

                  const SizedBox(height: 25),
                  
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text("OR JOIN WITH", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    // 🔴 8. Button Disable During Loading
                    onPressed: _isLoading ? null : handleGoogleSignIn,
                    icon: const Text(
                      "G",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    label: const Text(
                      "Continue with Google", 
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15)
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      backgroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?", style: TextStyle(color: Colors.grey[700])),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Login", 
                          style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {TextInputType inputType = TextInputType.text, 
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    Iterable<String>? autofillHints}
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscureText,
        autofillHints: autofillHints,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: onTogglePassword,
              )
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
