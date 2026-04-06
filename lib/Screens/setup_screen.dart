import 'package:flutter/material.dart';
import '../services/setup_logic.dart';
import '../Core/theme/app_colors.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final SetupLogic _setupLogic = SetupLogic();
  int _currentStep = 0;
  bool _isLoading = false;

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _finishSetup();
    }
  }

  void _finishSetup() async {
    setState(() => _isLoading = true);
    // Simulate a brief setup process
    await Future.delayed(const Duration(seconds: 1)); 
    if (mounted) {
      await _setupLogic.completeSetup(context);
    }
  }

  Widget _buildStep(String title, String description, IconData icon) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
         return FadeTransition(
           opacity: animation, 
           child: ScaleTransition(scale: animation, child: child)
         );
      },
      child: Column(
        key: ValueKey<int>(_currentStep),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> steps = [
      {
        'title': 'Welcome to Smart Irrigation',
        'desc': 'Take control of your water usage and ensure your plants thrive with minimal effort.',
        'icon': Icons.water_drop_outlined
      },
      {
        'title': 'Automate Your Schedules',
        'desc': 'Set up customized watering times or let our smart system decide based on live data.',
        'icon': Icons.schedule_outlined
      },
      {
        'title': 'Real-Time Insights',
        'desc': 'Monitor soil moisture and weather forecasts right from your dashboard.',
        'icon': Icons.analytics_outlined
      }
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildStep(
                steps[_currentStep]['title'],
                steps[_currentStep]['desc'],
                steps[_currentStep]['icon'],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        height: 10,
                        width: _currentStep == index ? 25 : 10,
                        decoration: BoxDecoration(
                          color: _currentStep == index ? AppColors.primary : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _isLoading 
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      _currentStep == steps.length - 1 ? "GET STARTED" : "NEXT",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
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
