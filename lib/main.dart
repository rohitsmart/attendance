import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_project/screen/dashboard_screen.dart';
import 'package:flutter_project/screen/login_screen.dart';
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
              home: DashboardScreen(token),
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
              initialRoute: '/login',
              routes: {
                '/login': (context) => const LoginScreen(),
              },
            );
          }
        }
      },
    );
  }
}
