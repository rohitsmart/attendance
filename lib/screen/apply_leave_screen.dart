import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'dashboard_screen.dart';

class ApplyLeaveScreen extends StatefulWidget {
  final String token;

  const ApplyLeaveScreen(this.token, {Key? key}) : super(key: key);

  @override
  _ApplyLeaveScreenState createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();

  String _leaveType = 'PL';
  late String _note;
  late String _fromDate;
  late String _toDate;
  late String _email;
  late String _employeeCode;
  late String _employeeName;
  late String _managerCode;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
    _setInitialDates();
  }

  Future<void> _fetchEmployeeData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _employeeCode = prefs.getString('employeeCode') ?? '';
    _employeeName = prefs.getString('fullName') ?? '';
    _managerCode = prefs.getString('managerEmpCode') ?? '';
    _email = prefs.getString('userEmail') ?? '';
    setState(() {});
  }

  void _setInitialDates() {
    _fromDate = _formatDate(DateTime.now());
    _toDate = _formatDate(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _submitLeaveRequest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final Map<String, dynamic> payload = {
        'leaveType': _leaveType,
        'email': [_email],
        'note': _note,
        'fromDate': _fromDate,
        'toDate': _toDate,
        'employeeCode': _employeeCode,
        'employeeName': _employeeName,
        'managerCode': _managerCode,
      };

      final Uri uri = Uri.parse('http://179.61.188.36:9000/api/leave/create');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}'
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        // Leave request submitted successfully
        await Future.delayed(const Duration(seconds: 2));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(widget.token)),
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
    if (picked != null) {
      setState(() {
        _fromDate = _formatDate(picked);
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
    if (picked != null) {
      setState(() {
        _toDate = _formatDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Leave Type',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a note';
                  }
                  return null;
                },
                onSaved: (value) => _note = value!,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'From Date',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                controller: TextEditingController(text: _fromDate),
                onTap: () => _selectFromDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select from date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'To Date',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                controller: TextEditingController(text: _toDate),
                onTap: () => _selectToDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select to date';
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
