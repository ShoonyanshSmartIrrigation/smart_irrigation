import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../Routes/app_Routes.dart';
import '../Widgets/build_header.dart';
import '../Core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<bool> _checkInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      showToast("No internet connection. Please check your network.");
      return false;
    }
    return true;
  }

  void handleLogin() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showToast("Please fill all fields");
      return;
    }

    if (!_isValidEmail(email)) {
      showToast("Please enter a valid email address");
      return;
    }

    if (password.length < 6) {
      showToast("Password must be at least 6 characters");
      return;
    }

    if (!await _checkInternet()) return;

    setState(() => _isLoading = true);

    try {
      User? user = await _authService.loginWithEmail(email, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        showToast("Login Successful!");
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showToast(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showToast("An unexpected error occurred.");
    }
  }

  void handleGoogleSignIn() async {
    if (!await _checkInternet()) return;

    setState(() => _isLoading = true);

    try {
      User? user = await _authService.signInWithGoogle();
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        showToast("Logged in with Google!");
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      showToast(e.message);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      showToast("Google Sign-In failed.");
    }
  }

  void handleForgotPassword() async {
    String email = emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      showToast("Please enter a valid email address first");
      return;
    }

    if (!await _checkInternet()) return;

    try {
      await _authService.sendPasswordResetEmail(email);
      showToast("Password reset link sent to your email");
    } on AuthException catch (e) {
      showToast(e.message);
    } catch (e) {
      showToast("Something went wrong. Try again.");
    }
  }

  void showToast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.primary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            BuildHeader(
              height: 250,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.loginHeaderIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco_rounded, size: 60, color: AppColors.white),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Smart Irrigation",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    "Sustainable Future Begins Here",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.loginSubtitle,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Login to your account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  _buildTextField(
                    emailController, 
                    "Email Address", 
                    Icons.email_outlined, 
                    inputType: TextInputType.emailAddress,
                    autofillHints: [AutofillHints.email],
                  ),
                  const SizedBox(height: 18),
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

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: handleForgotPassword,
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(
                    onPressed: handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      shadowColor: AppColors.loginButtonShadow,
                    ),
                    child: const Text(
                      "LOGIN",
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text("OR CONNECT WITH", style: const TextStyle(color: AppColors.loginTextGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 25),

                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : handleGoogleSignIn,
                    icon: SvgPicture.asset(
                      "assets/svg/google.svg",
                      height: 24,
                    ),
                    label: const Text(
                      "Continue with Google",
                      style: TextStyle(color: AppColors.loginGoogleButtonText, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      side: const BorderSide(color: AppColors.loginDivider, width: 1.5),
                      backgroundColor: AppColors.loginGoogleButtonBg,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?", style: TextStyle(color: AppColors.loginTextDarkGrey)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
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
    Iterable<String>? autofillHints,
    VoidCallback? onTogglePassword}
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.loginTextFieldBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.loginShadow,
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
          labelStyle: const TextStyle(color: AppColors.loginTextGrey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: AppColors.grey),
                onPressed: onTogglePassword,
              )
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.loginTextFieldBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
