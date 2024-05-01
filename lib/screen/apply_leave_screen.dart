import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_screen.dart';

class ApplyLeaveScreen extends StatefulWidget {
  final String token;

  const ApplyLeaveScreen(this.token, {Key? key}) : super(key: key);

  @override
  _ApplyLeaveScreenState createState() => _ApplyLeaveScreenState();
}
class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();

  String _leaveType = 'PL'; // Initialize _leaveType with a default value
  late String _note;
  late String _fromDate;
  late String _toDate;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
    _setInitialDates();

  }

  Future<void> _fetchEmployeeData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String employeeCode = prefs.getString('employeeCode') ?? '';
    final String email = prefs.getString('userEmail') ?? '';
    final String token = prefs.getString('token') ?? '';
    setState(() {
      // Set initial values for fromDate and toDate
      _fromDate = DateTime.now().toString();
      _toDate = DateTime.now().toString();
    });
  }
  void _setInitialDates() {
    _fromDate = _formatDate(DateTime.now());
    _toDate = _formatDate(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return DateFormat('d M y').format(date);
  }
  Future<void> _submitLeaveRequest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String employeeCode = prefs.getString('employeeCode') ?? '';
      final String employeeName = prefs.getString('employeeName') ?? '';
      final String managerCode = prefs.getString('managerCode') ?? '';
      final String email = prefs.getString('userEmail') ?? '';

      final Map<String, dynamic> payload = {
        'leaveType': _leaveType,
        'email': [email],
        'note': _note,
        'fromDate': _fromDate,
        'toDate': _toDate,
        'employeeCode': employeeCode,
        'employeeName': employeeName,
        'managerCode': managerCode,
      };

      final Uri uri = Uri.parse('http://179.61.188.36:9000/api/leave/create');
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        // Leave request submitted successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );

      } else {
        // Error submitting leave request
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit leave request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != DateTime.parse(_fromDate)) {
      setState(() {
        _fromDate = DateFormat('d M y').format(picked);
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != DateTime.parse(_toDate)) {
      setState(() {
        _toDate = DateFormat('d M y').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Leave Type'),
                value: _leaveType,
                items: ['PL', 'UL', 'CL', 'SL']
                    .map<DropdownMenuItem<String>>(
                      (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                    .toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select leave type';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _leaveType = value!;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Note'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a note';
                  }
                  return null;
                },
                onSaved: (value) => _note = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'From Date'),
                readOnly: true,
                controller: TextEditingController(text: _fromDate),
                onTap: () => _selectFromDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter from date';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'To Date'),
                readOnly: true,
                controller: TextEditingController(text: _toDate),
                onTap: () => _selectToDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter to date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitLeaveRequest,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
