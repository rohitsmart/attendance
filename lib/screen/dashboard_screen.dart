import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/screen/attendance_screen.dart';
import 'package:flutter_project/screen/login_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'apply_leave_screen.dart';
import 'leave_screen.dart';

class DashboardScreen extends StatelessWidget {

  static const _attendanceIcon = AssetImage('lib/assets/attendance.png');
  static const _leavesIcon = AssetImage('lib/assets/leave.png');
  static const _punchIcon = AssetImage('lib/assets/TimeIn.png');


  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Dashboard'),
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
    ),
    drawer: Drawer(
      child: FutureBuilder(
        future: Future.wait([
          _getUserInfo('userEmail'),
          _getUserInfo('employeeCode'),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else {
            final List<String?> userInfo = snapshot.data as List<String?>;
            final String? userEmail = userInfo[0];
            final String? employeeCode = userInfo[1];

            return ListView(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(userEmail ?? ''),
                  accountEmail: Text('Employee Code: ${employeeCode ?? ''}'),
                  currentAccountPicture: const CircleAvatar(
                    child: Text('U'),
                  ),
                ),
                const Divider(),
                ExpansionTile(
                  title: const Text('Leave'),
                  children: [
                    ListTile(
                      title: const Text('My Leaves'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyLeavesScreen(token)),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text('Apply for Leave'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ApplyLeaveScreen(token)),
                        );
                      },
                    ),
                  ],
                ),
                ListTile(
                  title: const Text('Attendance'),
                  onTap: () {
                    // Navigate to Attendance screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AttendanceScreen(token)),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Policy'),
                  onTap: () {
                  },
                ),
                ListTile(
                  title: const Text('Tasks'),
                  onTap: () {
                  },
                ),
                ListTile(
                  title: const Text('Logout'),
                  onTap: () => _logout(context),
                ),
              ],
            );
          }
        },
      ),
    ),
    
    bottomNavigationBar: BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Image(
            image: _attendanceIcon,
            height: 40,
            width: 40,
            color: Color(0xff2cc9fc),
          ),
          label: 'Attendance',
        ),
        BottomNavigationBarItem(
          icon: Image(
            image: _leavesIcon,
            height: 40,
            width: 40,
          ),
          label: 'My Leaves',
        ),
      ],
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.orange,
      onTap: (int index) {
      },
    ),

    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder<String?>(
            future: _getUserInfo('fullName'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                final String? fullName = snapshot.data;
                final String greetingMessage = _getGreetingMessage();

                  return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$greetingMessage,',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$fullName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tap below to mark your Attendance',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),

                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation.drive(Tween<double>(begin: 0.95, end: 1.05)),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () {
                _markAttendance(context);
              },
             child: const SizedBox(
                width: 120,
                height: 120,
                child: Image(
                  image: _punchIcon,
                  width: 60,
                  height: 60,
                ),
              ),
            ),
          ),
        ],
      ),
    ),

  );
}


final String token;

const DashboardScreen(this.token, {Key? key}) : super(key: key);

Future<String?> fetchWifiName() async {
  try {
    if (!kIsWeb) {
      final info = NetworkInfo();
      final wifiName = await info.getWifiName();
      if (kDebugMode) {
        print('Wifi Name: $wifiName  ');
      }
      if (wifiName != null) {
        return wifiName;
      }
    }
  } on PlatformException catch (error) {
    debugPrint('Error fetching Wi-Fi name: $error');
  }
  return null;
}

Future<void> _markAttendance(BuildContext context) async {
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

  final Position? position = await _fetchLocation();
  if (position == null) {
    Navigator.pop(context); // Dismiss the loader
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to fetch location'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  final double latitude = position.latitude!;
  final double longitude = position.longitude!;
  final bool isInLocationRange = _isInLocationRange(latitude, longitude);
  if (!isInLocationRange) {
    Navigator.pop(context); // Dismiss the loader
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You are not in the allowed location range. Latitude: $latitude, Longitude: $longitude'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
    return;
  }

  final headers = {
    'Authorization': 'Bearer $token',
  };
  final responseFuture = http.post(
    Uri.parse("http://179.61.188.36:9000/api/attendence/web-online"),
    headers: headers,
  );

  // Wait for 2 seconds before checking if the response is received
  await Future.delayed(Duration(seconds: 2));

  responseFuture.then((response) {
    Navigator.pop(context); // Dismiss the loader

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance Marked Successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceScreen(token),
        ),
      );

      if (kDebugMode) {
        print("Attendance marked successfully");
      }
    } else {
      // Handle error response
      String errorMessage;
      if (response.body.isNotEmpty) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? 'Attendance Failed';
      } else {
        errorMessage = 'Login Failed';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  });

  // Wait for 10 seconds before showing error if the response is not received
  await Future.delayed(Duration(seconds: 10));
  Navigator.pop(context); // Dismiss the loader
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Attendance Failed: No response from server'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 2),
    ),
  );
}

Future<String?> _getUserInfo(String key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<Position?> _fetchLocation() async {
  bool serviceEnabled;
  LocationPermission permission;
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return null;
  }
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return null;
    }
  }
  return await Geolocator.getCurrentPosition();
}

bool _isInLocationRange(double latitude, double longitude) {
  const double officeLatitude = 28.586337;
  const double officeLongitude = 77.316019;
  const double maxDeviation = 0.05;
  final bool isInLatitudeRange = (latitude >= officeLatitude - maxDeviation && latitude <= officeLatitude + maxDeviation);
  final bool isInLongitudeRange = (longitude >= officeLongitude - maxDeviation && longitude <= officeLongitude + maxDeviation);

  return isInLatitudeRange && isInLongitudeRange;
}

Future<void> _logout(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Logged out successfully'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ),
  );

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginScreen()),
  );
}

String _getGreetingMessage() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good morning';
  } else if (hour < 17) {
    return 'Good Afternoon';
  } else {
    return 'Good Evening';
  }
}

}
