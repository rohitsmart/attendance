import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
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
  bool _isObscure = true;

  bool isEmailValid(String email) {
    String pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }
  void _togglePasswordVisibility() {
    setState(() {
      _isObscure = !_isObscure;
    });
  }

  Future<void> _login(BuildContext context) async {
    String email = '${emailController.text.trim()}@perfectkode.com';

    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!isEmailValid(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedEmail = prefs.getString('userEmail');

    if (storedEmail != null && storedEmail.isNotEmpty && storedEmail != email) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unauthorized'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: SizedBox(
            width: 150,
            height: 150,
            child: LoadingAnimationWidget.twistingDots(
              leftDotColor: const Color(0xFF1A1A3F),
              rightDotColor: const Color(0xFFEA3799),
              size: 50,
            ),
          ),
        );
      },
    );

    final responseFuture = http.post(
      Uri.parse("http://179.61.188.36:9000/api/employee/login"),
      body: {"email": email, "password": password},
    );

    // Wait for 2 seconds before checking if the response is received
    await Future.delayed(Duration(seconds: 2));

    responseFuture.then((response) async {
      Navigator.pop(context); // Dismiss the loader

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String token = data['auth']['token'];
        final String employeeCode = data['user']['employeeCode'];
        final String managerEmpCode = data['user']['ManagerEmpCode'];
        final String userEmail = data['user']['email'];
        final String firstName = data['user']['first_name'];
        final String lastName = data['user']['lastName'];
        final String fullName = '$firstName $lastName';
        await prefs.setString('token', token);
        await prefs.setString('employeeCode', employeeCode);
        await prefs.setString('managerEmpCode', managerEmpCode);
        await prefs.setString('userEmail', userEmail);
        await prefs.setString('fullName', fullName);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Successful'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Delay navigation to the next screen by 2 seconds
        await Future.delayed(Duration(seconds: 2));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(token)),
        );
      } else {
        if (response.body.isNotEmpty) {
          final Map<String, dynamic> errorData = json.decode(response.body);
          final String errorMessage = errorData['message'] ?? 'Login Failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Failed'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }
    });

    // Wait for 10 seconds before showing error if the response is not received
    await Future.delayed(Duration(seconds: 10));
    Navigator.pop(context); // Dismiss the loader
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login Failed: No response from server'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
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
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Your email without @perfectkode.com',
              ),
            ),
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: _togglePasswordVisibility,
              ),
            ),
            obscureText: _isObscure,
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
