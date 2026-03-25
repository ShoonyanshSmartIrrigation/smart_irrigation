import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool showOtpSection = false;

  void handleSendOtp() {
    bool isValid = _authService.validateUserInput(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
    );

    if (isValid) {
      String otp = _authService.generateOtp();
      showToast("OTP Sent\nOTP: $otp");
      setState(() {
        showOtpSection = true;
      });
    } else {
      showToast("Please enter valid details");
    }
  }

  void handleVerifyOtp() async {
    if (!_authService.validateOtp(otpController.text.trim())) {
      showToast("Please enter a valid 6-digit OTP");
      return;
    }

    bool success = await _authService.verifyOtp(
      otpController.text.trim(),
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
    );

    if (success) {
      showToast("OTP Verified");
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
    } else {
      showToast("Invalid OTP");
      otpController.clear();
    }
  }

  void showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.eco, size: 80, color: Color(0xFF2E7D32)),
            const SizedBox(height: 10),
            const Text(
              "Smart Irrigation",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 40),
            _buildTextField(nameController, "Full Name", Icons.person),
            const SizedBox(height: 16),
            _buildTextField(phoneController, "Phone Number", Icons.phone, inputType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(emailController, "Email Address", Icons.email, inputType: TextInputType.emailAddress),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: handleSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("SEND OTP", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),

            if (showOtpSection) ...[
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
              _buildTextField(otpController, "Enter 6-digit OTP", Icons.lock_clock, inputType: TextInputType.number),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: handleVerifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("VERIFY & LOGIN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
    );
  }
}
