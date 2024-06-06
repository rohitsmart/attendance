// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:flutter_project/screen/dashboard_screen.dart';
// import 'package:flutter_project/screen/login_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// void main() {
//   runApp(const MyApp());
// }
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key});
//
//   Future<void> _fetchAppIcon() async {
//     const String iconUrl = "https://perfectkode.com/static/media/logo.ed7cf56626446ad06ce0.png";
//     final DefaultCacheManager cacheManager = DefaultCacheManager();
//     final File file = await cacheManager.getSingleFile(iconUrl);
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('appIconPath', file.path);
//   }
//
//   Future<String?> _getToken() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString('token');
//   }
//   @override
//   Widget build(BuildContext context) {
//     _fetchAppIcon();
//     return FutureBuilder<String?>(
//       future: _getToken(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const CircularProgressIndicator();
//         } else {
//           final String? token = snapshot.data;
//           if (token != null) {
//             return MaterialApp(
//               title: 'PK',
//               theme: ThemeData(
//                 primarySwatch: Colors.blue,
//                 // Load app icon dynamically
//                 appBarTheme: const AppBarTheme(
//                   iconTheme: IconThemeData(
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               home: DashboardScreen(token),
//             );
//           } else {
//             return MaterialApp(
//               title: 'PK',
//               theme: ThemeData(
//                 primarySwatch: Colors.blue,
//                 // Load app icon dynamically
//                 appBarTheme: const AppBarTheme(
//                   iconTheme: IconThemeData(
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               initialRoute: '/login',
//               routes: {
//                 '/login': (context) => const LoginScreen(),
//               },
//             );
//           }
//         }
//       },
//     );
//   }
// }



import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/screen/dashboard_screen.dart';
import 'package:flutter_project/screen/login_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
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
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<String?> _tokenFuture;
  late Future<void> _fetchAppIconFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = _getToken();
    _fetchAppIconFuture = _fetchAppIcon();
  }

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

  Future<bool> _checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status == PermissionStatus.granted;
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status != PermissionStatus.granted) {
      // Permission not granted, handle accordingly
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required for the app to function properly.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, tokenSnapshot) {
        return FutureBuilder<bool>(
          future: _checkLocationPermission(),
          builder: (context, permissionSnapshot) {
            if (tokenSnapshot.connectionState == ConnectionState.waiting ||
                permissionSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              final String? token = tokenSnapshot.data;
              final bool hasLocationPermission = permissionSnapshot.data ?? false;
              if (token != null) {
                if (!hasLocationPermission) {
                  _requestLocationPermission();
                }
                return DashboardScreen(token);
              } else {
                return const LoginScreen();
              }
            }
          },
        );
      },
    );
  }
}
