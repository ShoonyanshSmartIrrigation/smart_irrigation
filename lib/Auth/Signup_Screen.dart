import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../Routes/app_routes.dart';
import '../Core/theme/app_colors.dart';
import '../Widgets/build_header.dart';

//-------------------------------------------------------- SignupScreen Class ----------------------------------------------------------
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

//-------------------------------------------------------- _SignupScreenState Class ----------------------------------------------------------
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
  bool _isSignupLoading = false;
  bool _isGoogleLoading = false;
  String _passwordStrength = "";
  Color _strengthColor = Colors.transparent;

  @override
    //-------------------------------------------------------- Init State ----------------------------------------------------------
  void initState() {
    super.initState();
    passwordController.addListener(_checkPasswordStrength);
  }

  @override
    //-------------------------------------------------------- Dispose Method ----------------------------------------------------------
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
    if (_isSignupLoading) return;

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

    setState(() => _isSignupLoading = true);

    try {
      User? user = await _authService.signUpWithEmail(email, password, name, phone);

      if (!mounted) return;
      setState(() => _isSignupLoading = false);

      if (user != null) {
        showToast("Signup Successful!");
        context.go(AppRoutes.dashboard);
      } else {
        showToast("Signup Failed. Please check your details.");
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSignupLoading = false);
      showToast(e.message ?? "An error occurred during signup");
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSignupLoading = false);
      showToast("Something went wrong. Please try again.");
    }
  }

  void handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      showToast("No internet connection");
      return;
    }

    setState(() => _isGoogleLoading = true);

    try {
      User? user = await _authService.signInWithGoogle();
      
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      if (user != null) {
        showToast("Logged in with Google!");
        context.go(AppRoutes.dashboard);
      } else {
        showToast("Google Sign-In failed.");
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      showToast(e.message ?? "Google Sign-In failed");
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
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
    //-------------------------------------------------------- Build Method ----------------------------------------------------------
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
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

                    _isSignupLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ElevatedButton(
                      onPressed: _isGoogleLoading ? null : handleSignUp,
                      style: ElevatedButton.styleFrom(
                        splashFactory: NoSplash.splashFactory,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                        shadowColor: AppColors.signupButtonShadow,
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
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

                    _isGoogleLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ElevatedButton(
                      onPressed: _isSignupLoading ? null : handleGoogleSignIn,
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

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? ", style: TextStyle(color: AppColors.signupTextGrey)),
                        TextButton(
                          onPressed: () => context.pop(),
                          style: ButtonStyle(
                            overlayColor: WidgetStateProperty.all(Colors.transparent),
                          ),
                          child: const Text('Login', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator}
  ) {
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: inputType,
                textInputAction: textInputAction,
                obscureText: obscureText,
                autofillHints: autofillHints,
                inputFormatters: inputFormatters,
                onChanged: (value) => state.didChange(value),
                onSubmitted: (value) {
                  if (nextFocusNode != null) {
                    FocusScope.of(context).requestFocus(nextFocusNode);
                  }
                  if (onFieldSubmitted != null) {
                    onFieldSubmitted(value);
                  }
                },
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: AppColors.signupTextGrey, fontSize: 14),
                  prefixIcon:  Icon(icon, color: AppColors.primary, size: 22),
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
                  fillColor: AppColors.signupTextFieldBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 6),
                child: Text(
                  state.errorText!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        );
      },
    );
  }
}
