import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_svg/svg.dart';
import '../Routes/app_Routes.dart';
import '../Widgets/build_header.dart';
import '../services/auth_service.dart';
import '../Core/theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _passwordStrength = "";
  Color _strengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    
    passwordController.removeListener(_checkPasswordStrength);
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    String pass = passwordController.text;
    if (pass.isEmpty) {
      setState(() {
        _passwordStrength = "";
        _strengthColor = Colors.transparent;
      });
    } else if (pass.length < 6) {
      setState(() {
        _passwordStrength = "Weak (Too short)";
        _strengthColor = Colors.red;
      });
    } else if (!RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$').hasMatch(pass)) {
      setState(() {
        _passwordStrength = "Medium (Add Uppercase, Number, Special Char)";
        _strengthColor = Colors.orange;
      });
    } else {
      setState(() {
        _passwordStrength = "Strong Password";
        _strengthColor = Colors.green;
      });
    }
  }

  void handleSignUp() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    String name = nameController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      showToast("Enter valid email");
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      showToast("Enter valid phone number");
      return;
    }

    if (name.length < 3) {
      showToast("Name too short");
      return;
    }
    
    if (password.length < 6) {
      showToast("Password must be at least 6 characters");
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      showToast("No internet connection");
      return;
    }

    setState(() => _isLoading = true);

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
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showToast(e.message ?? "An error occurred during signup");
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showToast("Something went wrong. Please try again.");
    }
  }

  void handleGoogleSignIn() async {
    if (_isLoading) return;

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      showToast("No internet connection");
      return;
    }

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
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showToast(e.message ?? "Google Sign-In failed");
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showToast("Google Sign-In error occurred.");
    }
  }

  void showToast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.signupBackground,
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
                    decoration: const BoxDecoration(
                      color: AppColors.signupHeaderIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_rounded, size: 50, color: AppColors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Text(
                    "Start managing your irrigation smarter",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.signupSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      nameController, 
                      "Full Name", 
                      Icons.person_outline, 
                      focusNode: _nameFocus,
                      nextFocusNode: _phoneFocus,
                      textInputAction: TextInputAction.next,
                      autofillHints: [AutofillHints.name],
                      validator: (value) => (value == null || value.isEmpty) ? "Name is required" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      phoneController, 
                      "Phone Number", 
                      Icons.phone_android_outlined, 
                      focusNode: _phoneFocus,
                      nextFocusNode: _emailFocus,
                      inputType: TextInputType.phone, 
                      textInputAction: TextInputAction.next,
                      autofillHints: [AutofillHints.telephoneNumber],
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Phone number is required";
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) return "Enter valid 10-digit number";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      emailController, 
                      "Email Address", 
                      Icons.email_outlined, 
                      focusNode: _emailFocus,
                      nextFocusNode: _passwordFocus,
                      inputType: TextInputType.emailAddress, 
                      textInputAction: TextInputAction.next,
                      autofillHints: [AutofillHints.email],
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Email is required";
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value)) return "Enter valid email";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      passwordController, 
                      "Password", 
                      Icons.lock_outline_rounded, 
                      focusNode: _passwordFocus,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: [AutofillHints.password],
                      onTogglePassword: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      validator: (value) => (value == null || value.length < 6) ? "Password must be at least 6 characters" : null,
                      onFieldSubmitted: (_) => handleSignUp(),
                    ),
                    
                    if (_passwordStrength.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          _passwordStrength,
                          style: TextStyle(color: _strengthColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),

                    const SizedBox(height: 30),

                    _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ElevatedButton(
                      onPressed: _isLoading ? null : handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                        shadowColor: AppColors.signupButtonShadow,
                      ),
                      child: const Text(
                        "SIGN UP", 
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)
                      ),
                    ),

                    const SizedBox(height: 25),
                    
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("OR JOIN WITH", style: TextStyle(color: AppColors.signupTextGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 20),

                    OutlinedButton(
                      onPressed: _isLoading ? null : handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        side: const BorderSide(color: AppColors.signupDivider, width: 1.5),
                        backgroundColor: AppColors.signupGoogleButtonBg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/svg/google.svg',
                            height: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Continue with Google", 
                            style: TextStyle(color: AppColors.signupGoogleButtonText, fontWeight: FontWeight.w600, fontSize: 15)
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?", style: TextStyle(color: AppColors.signupTextDarkGrey)),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Login", 
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
    TextInputAction? textInputAction,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    void Function(String)? onFieldSubmitted,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator}
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.signupTextFieldBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: AppColors.signupShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: inputType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        autofillHints: autofillHints,
        validator: validator,
        onFieldSubmitted: (value) {
          if (nextFocusNode != null) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          }
          if (onFieldSubmitted != null) {
            onFieldSubmitted(value);
          }
        },
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.signupTextGrey, fontSize: 14),
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
          fillColor: AppColors.signupTextFieldBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
