
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Leave {
  final String id;
  final String fromDate;
  final String toDate;
  final String leaveType;
  final String note;
  final String managerApproval;
  final String hrApproval;

  Leave({
    required this.id,
    required this.fromDate,
    required this.toDate,
    required this.leaveType,
    required this.note,
    required this.managerApproval,
    required this.hrApproval,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['_id'],
      fromDate: json['fromDate'],
      toDate: json['toDate'],
      leaveType: json['leaveType'],
      note: json['note'],
      managerApproval: json['manager_leave_status'],
      hrApproval: json['hr_leave_status'],
    );
  }

  Color getStatusColor() {
    if (managerApproval == 'approved' || hrApproval == 'approved') {
      return Colors.green;
    }
    else if (managerApproval == 'rejected' || hrApproval == 'rejected') {
      return Colors.red;
    }
    else {
      return Colors.orange;
    }
  }

}

class MyLeavesScreen extends StatefulWidget {
  final String token;

  const MyLeavesScreen(this.token, {Key? key}) : super(key: key);

  @override
  _MyLeavesScreenState createState() => _MyLeavesScreenState();
}

class _MyLeavesScreenState extends State<MyLeavesScreen> {
  List<Leave> _leaveRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaveRecords();
  }

  Future<void> _fetchLeaveRecords() async {
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token') ?? '';

    final Uri uri = Uri.parse('http://179.61.188.36:9000/api/leave/list-all');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {

      final List<dynamic> responseData = json.decode(response.body)['result'];
      setState(() {
        _leaveRecords = responseData.map((data) => Leave.fromJson(data)).toList();
      });
      Navigator.pop(context); // Dismiss the loader

    } else {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leaves'),
      ),
      body: SingleChildScrollView(
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _leaveRecords.length,
          itemBuilder: (context, index) {
            final leave = _leaveRecords[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Type: ${leave.leaveType}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('From Date: ${leave.fromDate}'),
                    Text('To Date: ${leave.toDate}'),
                    Text('Note: ${leave.note}'),
                    Text(
                      'Manager Approval: ${leave.managerApproval}',
                      style: TextStyle(color: leave.getStatusColor()),
                    ),
                    Text(
                      'HR Approval: ${leave.hrApproval}',
                      style: TextStyle(color: leave.getStatusColor()),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
