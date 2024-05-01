import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/screen/attendance_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'apply_leave_screen.dart';
import 'leave_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String token;

  const DashboardScreen(this.token, {Key? key}) : super(key: key);

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
      if (response.body.isNotEmpty) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage = errorData['message'] ?? 'Attendance Failed';
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
      }
    }
  }

  Future<String?> _getUserInfo(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

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
            icon: Icon(Icons.notifications),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Help',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          // Handle bottom navigation item tap
        },
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'Welcome to Dashboard!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _markAttendance(context),
        tooltip: 'Mark Attendance',
        child: const Icon(Icons.check), // You can change the icon here
      ),
    );
  }
}
