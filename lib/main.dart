import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  Future<void> _fetchAppIcon() async {
    const String iconUrl = "https://perfectkode.com/static/media/logo.ed7cf56626446ad06ce0.png";
    final DefaultCacheManager cacheManager = DefaultCacheManager();
    final File file = await cacheManager.getSingleFile(iconUrl);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('appIconPath', file.path);
  }

  Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Widget build(BuildContext context) {
    _fetchAppIcon();
    return FutureBuilder<String?>(
      future: _getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          final String? token = snapshot.data;
          if (token != null) {
            return MaterialApp(
              title: 'PK',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                // Load app icon dynamically
                appBarTheme: const AppBarTheme(
                  iconTheme: IconThemeData(
                    color: Colors.white,
                  ),
                ),
              ),
              home: AttendanceScreen(token),
            );
          } else {
            return MaterialApp(
              title: 'PK',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                // Load app icon dynamically
                appBarTheme: const AppBarTheme(
                  iconTheme: IconThemeData(
                    color: Colors.white,
                  ),
                ),
              ),
              home: const LoginScreen(),
            );
          }
        }
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Successful'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AttendanceScreen(token)),
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

class AttendanceScreen extends StatelessWidget {
  final String token;
  const AttendanceScreen(this.token, {Key? key});

  Future<void> _markAttendance(BuildContext context) async {
    final headers = {
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse("http://179.61.188.36:9000/api/attendence/web-online"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance Marked Successfully'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
      );

      if (kDebugMode) {
        print("Attendance marked successfully");
      }
    } else {
      if (response.body.isNotEmpty) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage = errorData['message'] ?? 'Attendance Failed';
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
      appBar: AppBar(title: const Text('Attendance')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _markAttendance(context),
          child: const Text('Mark Attendance'),
        ),
      ),
    );
  }
}




