import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget  {
  const LoginScreen({Key? key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    final response = await http.post(
      Uri.parse("http://179.61.188.36:9000/api/employee/login"),
      body: {"email": email, "password": password},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final String token = data['auth']['token'];
      final String employeeCode = data['user']['employeeCode'];
      final String managerEmpCode = data['user']['ManagerEmpCode'];
      final String userEmail = data['user']['email'];
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('employeeCode', employeeCode);
      await prefs.setString('managerEmpCode', managerEmpCode);
      await prefs.setString('userEmail', userEmail);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Successful'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen(token)),
      );
    } else {
      if (response.body.isNotEmpty) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage = errorData['message'] ?? 'Login Failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
        );
      } else {
        // Handle other non-server related errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Failed'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
