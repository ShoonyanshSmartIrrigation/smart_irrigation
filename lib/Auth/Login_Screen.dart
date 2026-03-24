import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Screens/Dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  String generatedOtp = "";
  bool showOtpSection = false;

  // Validate user input
  bool validateUserInput() {
    String name = nameController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();

    if (name.isEmpty) {
      showToast("Please enter your name");
      return false;
    } else if (phone.isEmpty || phone.length < 10) {
      showToast("Please enter valid phone number");
      return false;
    } else if (email.isEmpty || !email.contains("@")) {
      showToast("Please enter valid email");
      return false;
    }
    return true;
  }

  // Validate OTP
  bool validateOtp() {
    String otp = otpController.text.trim();

    if (otp.isEmpty) {
      showToast("Please enter OTP");
      return false;
    } else if (otp.length != 6) {
      showToast("OTP must be 6 digits");
      return false;
    }
    return true;
  }

  // Generate OTP
  void generateOtp() {
    Random random = Random();
    generatedOtp = (100000 + random.nextInt(900000)).toString();

    showToast("OTP Sent\nOTP: $generatedOtp");

    setState(() {
      showOtpSection = true;
    });
  }

  // Verify OTP and Save Session
  void verifyOtp() async {
    if (otpController.text.trim() == generatedOtp) {
      showToast("OTP Verified");

      // Save user details in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', nameController.text.trim());
      await prefs.setString('userEmail', emailController.text.trim());
      await prefs.setString('userPhone', phoneController.text.trim());

      Future.delayed(Duration(seconds: 1), () {
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
        title: Text("Login", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            Icon(Icons.eco, size: 80, color: Color(0xFF2E7D32)),
            SizedBox(height: 10),
            Text(
              "Smart Irrigation",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
            SizedBox(height: 40),
            _buildTextField(nameController, "Full Name", Icons.person),
            SizedBox(height: 16),
            _buildTextField(phoneController, "Phone Number", Icons.phone, inputType: TextInputType.phone),
            SizedBox(height: 16),
            _buildTextField(emailController, "Email Address", Icons.email, inputType: TextInputType.emailAddress),

            SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                if (validateUserInput()) {
                  generateOtp();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("SEND OTP", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),

            if (showOtpSection) ...[
              SizedBox(height: 30),
              Divider(),
              SizedBox(height: 20),
              _buildTextField(otpController, "Enter 6-digit OTP", Icons.lock_clock, inputType: TextInputType.number),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (validateOtp()) {
                    verifyOtp();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("VERIFY & LOGIN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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
        prefixIcon: Icon(icon, color: Color(0xFF2E7D32)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
    );
  }
}
