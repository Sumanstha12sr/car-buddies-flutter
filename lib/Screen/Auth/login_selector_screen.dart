import 'package:flutter/material.dart';
import '../Staff/staff_login_screen.dart';
import 'login_screen.dart';

enum UserType { staff, customer }

class LoginSelectorScreen extends StatefulWidget {
  const LoginSelectorScreen({super.key});

  @override
  State<LoginSelectorScreen> createState() => _LoginSelectorScreenState();
}

class _LoginSelectorScreenState extends State<LoginSelectorScreen> {
  UserType selectedType = UserType.staff;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 🔘 Segmented Button
              Center(
                child: SegmentedButton<UserType>(
                  segments: const [
                    ButtonSegment(
                      value: UserType.customer,
                      label: Text("Customer"),
                    ),
                    ButtonSegment(value: UserType.staff, label: Text("Staff")),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (value) {
                    setState(() {
                      selectedType = value.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Colors.blue,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔁 Switch Screens
              Expanded(
                child: selectedType == UserType.staff
                    ? const StaffLoginScreen()
                    : const LoginScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
