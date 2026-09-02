import 'dart:io';
import 'package:flutter/foundation.dart'; // Provides kIsWeb
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class GuardInspectionScreen extends StatefulWidget {
  const GuardInspectionScreen({super.key});

  @override
  State<GuardInspectionScreen> createState() => _GuardInspectionScreenState();
}

class _GuardInspectionScreenState extends State<GuardInspectionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _guardNameController = TextEditingController();
  final _guardIdController = TextEditingController();
  final _actionLogController = TextEditingController();

  // Location / Check-In State
  bool _isCheckedIn = false;
  bool _isLocating = false;
  Position? _currentPosition;
  DateTime? _checkInTime;

  // Form State
  String _reportType = 'Routine Check';
  bool _uniformOk = true;
  bool _badgeVisible = true;
  bool _equipmentOk = true;

  // Submission State
  bool _isSubmitting = false;

  // Photo Picker
  XFile? _evidencePhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _guardNameController.dispose();
    _guardIdController.dispose();
    _actionLogController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied.');
          setState(() => _isLocating = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _currentPosition = position;
        _checkInTime = DateTime.now();
        _isCheckedIn = true;
        _isLocating = false;
      });

      _showSnackBar('Checked in at Site successfully!');
    } catch (e) {
      setState(() => _isLocating = false);
      _showSnackBar('Error getting location: $e');
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _evidencePhoto = photo;
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_isCheckedIn) {
      _showSnackBar('Please complete GPS Check-In first.');
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final reportData = {
          'siteName': 'City Mall - Main Entrance',
          'supervisor': _guardNameController.text.trim(),
          'badgeNumber': _guardIdController.text.trim(),
          'time': _checkInTime != null
              ? '${_checkInTime!.hour.toString().padLeft(2, '0')}:${_checkInTime!.minute.toString().padLeft(2, '0')}'
              : '08:00 AM',
          'type': _reportType,
          'status': 'Completed',
          'notes': _actionLogController.text.trim(),
          'uniformWorn': _uniformOk,
          'badgeVisible': _badgeVisible,
          'equipmentIntact': _equipmentOk,
          'coordinates': _currentPosition != null
              ? '${_currentPosition!.latitude}, ${_currentPosition!.longitude}'
              : '-1.286389, 36.817223',
        };

       bool success = await ApiService.submitSupervisorReport(
  reportData: reportData,
  photo: _evidencePhoto,
);

        if (mounted) {
          if (success) {
            _showSnackBar('Report Submitted & Sent to Office Dashboard!');
            _clearForm();
          } else {
            _showSnackBar('Failed to send report. Check backend server connection.');
          }
        }
      } catch (e) {
        if (mounted) _showSnackBar('Error sending report: $e');
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  void _clearForm() {
    _actionLogController.clear();
    _guardNameController.clear();
    _guardIdController.clear();
    setState(() {
      _reportType = 'Routine Check';
      _uniformOk = true;
      _badgeVisible = true;
      _equipmentOk = true;
      _evidencePhoto = null;
      _isCheckedIn = false;
      _currentPosition = null;
      _checkInTime = null;
    });
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0D47A1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Inspection Report'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Site',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'City Mall - Main Entrance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const Divider(height: 24),
                      _isCheckedIn
                          ? Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Arrived: ${_checkInTime.toString().substring(11, 16)} | GPS Locked',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ElevatedButton.icon(
                              onPressed: _isLocating ? null : _handleCheckIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(45),
                              ),
                              icon: _isLocating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.location_on),
                              label: Text(_isLocating
                                  ? 'Fetching Location...'
                                  : 'SWIPE / TAP TO CHECK-IN'),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Inspection Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _reportType,
                decoration: const InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Routine Check', 'Incident Log', 'Absence Alert']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _reportType = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _guardNameController,
                decoration: const InputDecoration(
                  labelText: 'Guard Name On Duty',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'Enter guard name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _guardIdController,
                decoration: const InputDecoration(
                  labelText: 'Guard Badge / ID Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) => v!.isEmpty ? 'Enter guard ID' : null,
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Full Uniform Worn'),
                        value: _uniformOk,
                        activeThumbColor: primaryBlue,
                        onChanged: (v) => setState(() => _uniformOk = v),
                      ),
                      SwitchListTile(
                        title: const Text('ID Badge Visible'),
                        value: _badgeVisible,
                        activeThumbColor: primaryBlue,
                        onChanged: (v) => setState(() => _badgeVisible = v),
                      ),
                      SwitchListTile(
                        title: const Text('Equipment Intact'),
                        value: _equipmentOk,
                        activeThumbColor: primaryBlue,
                        onChanged: (v) => setState(() => _equipmentOk = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _actionLogController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'What I Did / Supervisor Notes',
                  hintText: 'e.g., Verified guard post, checked perimeter gates.',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter notes' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_evidencePhoto == null ? 'Attach Photo' : 'Retake Photo'),
                  ),
                  const SizedBox(width: 12),
                  if (_evidencePhoto != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.network(
                              _evidencePhoto!.path,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_evidencePhoto!.path),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'Remove photo',
                      onPressed: () {
                        setState(() {
                          _evidencePhoto = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
    ? const Row(
        mainAxisAlignment: MainAxisAlignment.center, // Fixed parameter name
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'SUBMITTING...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      )
    : const Text(
        'SUBMIT REPORT TO OFFICE',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}