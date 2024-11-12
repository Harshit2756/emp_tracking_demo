import 'dart:io';

import 'package:emp_tracking_demo/services/attendance_service.dart';
import 'package:emp_tracking_demo/shared/storage_helper.dart';
import 'package:emp_tracking_demo/ui/employee/attedance.dart';
import 'package:emp_tracking_demo/ui/employee/camera_uid.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SubmitForm extends StatefulWidget {
  final XFile photo;
  final bool isEntry;

  const SubmitForm({super.key, required this.photo, required this.isEntry});

  @override
  State<SubmitForm> createState() => _SubmitFormState();
}

class _SubmitFormState extends State<SubmitForm> {
  bool _isLoading = false;
  bool _isLocationServiceEnabled = false;
  final AttendanceService _attendanceService = AttendanceService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEntry ? 'Submit Entry' : 'Submit Exit'),
        elevation: 0,
        // backgroundColor: Colors.teal[700],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(widget.photo.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!_isLocationServiceEnabled)
                Column(
                  children: [
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _enableLocationService,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Enable Location Services'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _retakePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Retake Photo'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.teal[700],
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: Colors.teal.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleSubmit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isLoading ? 'Submitting...' : 'Submit'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.teal[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: Colors.teal.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkLocationService();
  }

  Future<void> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _isLocationServiceEnabled = serviceEnabled;
    });
  }

  Future<void> _enableLocationService() async {
    await Geolocator.openLocationSettings();
    await _checkLocationService();
  }

  Future<void> _handleSubmit() async {
    if (!_isLocationServiceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable location services to submit.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Resize and convert image to base64
      final File imageFile = File(widget.photo.path);
      final img.Image? originalImage =
          img.decodeImage(await imageFile.readAsBytes());

      if (originalImage != null) {
        // Resize image maintaining aspect ratio
        final img.Image resizedImage = img.copyResize(originalImage,
            width: 300, height: 500, interpolation: img.Interpolation.linear);

        // Get current location
        Position position = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.medium));

        // Get user ID from secure storage
        String? userId = await StorageHelper.getUserId();
        if (userId == null) {
          throw Exception('User ID not found');
        }

        // Get current time in UTC
        DateTime now = DateTime.now().toUtc();

        // Prepare data to update with image
        Map<String, dynamic> updateData = widget.isEntry
            ? {
                'status': 'present',
                'transDate': DateFormat('dd-MM-yyyy').format(now).toString(),
                'inTime':
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(now).toString(),
                'lat': position.latitude.toString(),
                'lang': position.longitude.toString(),
              }
            : {
                'status': 'present',
                'transDate': DateFormat('dd-MM-yyyy').format(now).toString(),
                'exitTime':
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(now).toString(),
                'lat': position.latitude.toString(),
                'lang': position.longitude.toString(),
              };

        print(updateData);

        await _attendanceService.saveAttendance(
          data: updateData,
          image: resizedImage,
          file: imageFile,
          isEntry: widget.isEntry,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully submitted!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AttendancePage()),
          );
        }
      }
    } catch (e) {
      print('Error submitting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _retakePhoto() async {
    final XFile? newPhoto = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CameraUI(isEntry: widget.isEntry)),
    );

    if (newPhoto != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SubmitForm(photo: newPhoto, isEntry: widget.isEntry),
        ),
      );
    }
  }
}
