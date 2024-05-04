import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceScreen extends StatefulWidget {
  final String token;
  const AttendanceScreen(this.token, {Key? key}) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late String _selectedFilter;
  late String _fromDate;
  late String _toDate;
  late String _employeeCode;
  List<dynamic> _attendanceData = [];

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'Last 7 Days';
    _fetchEmployeeCode();
  }

  void _fetchEmployeeCode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _employeeCode = prefs.getString('employeeCode') ?? '';
    setState(() {
      _setDateRange();
    });
    Future.delayed(Duration.zero, () {
      _fetchAttendanceData();
    });
  }
  void _setDateRange() {
    DateTime today = DateTime.now();
    switch (_selectedFilter) {
      case 'Last 7 Days':
        _fromDate = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 6)));
        _toDate = DateFormat('yyyy-MM-dd').format(today);
        break;
      case 'Last 15 Days':
        _fromDate = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 14)));
        _toDate = DateFormat('yyyy-MM-dd').format(today);
        break;
      case 'Last 30 Days':
        _fromDate = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 29)));
        _toDate = DateFormat('yyyy-MM-dd').format(today);
        break;
      case 'Last 60 Days':
        _fromDate = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 59)));
        _toDate = DateFormat('yyyy-MM-dd').format(today);
        break;
    }
  }

  Future<void> _fetchAttendanceData() async {
    if (kDebugMode) {
      print("Fetching attendance data... $_employeeCode");
    } // Print when the function is called

    final Uri uri = Uri.parse(
        'http://179.61.188.36:9000/api/reports/attendance?f=$_fromDate&t=$_toDate&e=$_employeeCode');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer ${widget.token}'});

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      setState(() {
        _attendanceData = responseData['filterAttendance'];
      });
    } else {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButton<String>(
                    value: _selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                        _setDateRange();
                        _fetchAttendanceData();
                      });
                    },
                    items: <String>[
                      'Last 7 Days',
                      'Last 15 Days',
                      'Last 30 Days',
                      'Last 60 Days'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Table(
                border: TableBorder.all(color: Colors.grey),
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(3),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                    ),
                    children: const [
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Date',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Time In',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Time Out',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Remark',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  for (var attendance in _attendanceData)
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(attendance['attendDate']),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(attendance['in_time']),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(attendance['out_time']),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(attendance['remark']),
                          ),
                        ),
                      ],
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











