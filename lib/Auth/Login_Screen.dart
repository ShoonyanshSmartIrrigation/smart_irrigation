import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../Routes/app_routes.dart';
import '../services/auth_service.dart';
import '../Widgets/build_header.dart';
import '../Core/theme/app_colors.dart';

//-------------------------------------------------------- LoginScreen Class ----------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

//-------------------------------------------------------- _LoginScreenState Class ----------------------------------------------------------
class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoginLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
    //-------------------------------------------------------- Dispose Method ----------------------------------------------------------
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

    setState(() => _isLoginLoading = true);

    try {
      User? user = await _authService.loginWithEmail(email, password);

      if (!mounted) return;
      setState(() => _isLoginLoading = false);

      if (user != null) {
        showToast("Login Successful!");
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoginLoading = false);
      showToast("An unexpected error occurred.");
    }
  }

  void handleGoogleSignIn() async {
    if (!await _checkInternet()) return;

    setState(() => _isGoogleLoading = true);

    try {
      User? user = await _authService.signInWithGoogle();
      
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      if (user != null) {
        showToast("Logged in with Google!");
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) setState(() => _isGoogleLoading = false);
      showToast("Google Sign-In failed.");
    }
  }

  void handleForgotPassword() {
    context.push(AppRoutes.forgotPassword);
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
    //-------------------------------------------------------- Build Method ----------------------------------------------------------
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
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
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.loginHeaderIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco_rounded, size: 50, color: AppColors.white),
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
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                      ),
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

                  _isLoginLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(
                    onPressed: _isGoogleLoading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      splashFactory: NoSplash.splashFactory,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      shadowColor: AppColors.loginButtonShadow,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: const Text(
                      "LOGIN",
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("OR CONNECT WITH", style: TextStyle(color: AppColors.loginTextGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _isGoogleLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(
                    onPressed: _isLoginLoading ? null : handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      splashFactory: NoSplash.splashFactory,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.05),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/svg/google.svg",
                          height: 26,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Continue with Google",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?", style: TextStyle(color: AppColors.loginTextGrey)),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.signup),
                        style: ButtonStyle(
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                        ),
                        child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
        boxShadow: const [
          BoxShadow(
            color: AppColors.loginShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscureText,
        autofillHints: autofillHints,
        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.loginTextGrey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: AppColors.grey),
                onPressed: onTogglePassword,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
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

//-------------------------------------------------------- ForgotPasswordScreen Class ----------------------------------------------------------
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void handleReset() async {
    String email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      showToast("Please enter a valid email address");
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      showToast("No internet connection.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(email);
      showToast("Password reset link sent to your email");
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(220),
        child: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppColors.white),
          elevation: 0,
          flexibleSpace: BuildHeader(
            height: 300,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.loginHeaderIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset, size: 50, color: AppColors.white),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Forgot Password",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Reset Your Password",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Enter your email address and we will send you a link to reset your password.",
                    style: TextStyle(fontSize: 14, color: AppColors.loginTextGrey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.loginTextFieldBg,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.loginShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        labelStyle: const TextStyle(color: AppColors.loginTextGrey, fontSize: 14),
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.loginTextFieldBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ElevatedButton(
                          onPressed: handleReset,
                          style: ElevatedButton.styleFrom(
                            splashFactory: NoSplash.splashFactory,
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 4,
                            shadowColor: AppColors.loginButtonShadow,
                          ).copyWith(
                            overlayColor: WidgetStateProperty.all(Colors.transparent),
                          ),
                          child: const Text(
                            "SEND RESET LINK",
                            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
