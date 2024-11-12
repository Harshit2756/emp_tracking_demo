import 'package:emp_tracking_demo/shared/storage_helper.dart';
import 'package:emp_tracking_demo/ui/auth/login.dart';
import 'package:emp_tracking_demo/ui/employee/camera_uid.dart';
import 'package:emp_tracking_demo/ui/employee/view_entry.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data available'));
            }

            final userData = snapshot.data!;
            final employeeName = userData['name'] ?? 'User';
            final isEntryMarked = userData['isEntryMarked'] ?? false;
            final isExitMarked = userData['isExitMarked'] ?? false;
            final employeeId = userData['employeeId'];
            final entryTime = _formatTime(userData['entry_time']);
            final exitTime = _formatTime(userData['exit_time']);
            final entryImage = userData['entry_image'];
            final exitImage = userData['exit_image'];
            final entryLat = userData['entry_lat'];
            final entryLng = userData['entry_lng'];
            final exitLat = userData['exit_lat'];
            final exitLng = userData['exit_lng'];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome,',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employeeName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getCurrentDate(),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildAttendanceButton(
                              isMarked: isEntryMarked,
                              label: 'Entry',
                              onMark: () =>
                                  _openCameraUI(context, true, employeeId),
                              onView: () => _navigateToViewEntry(
                                  context,
                                  entryTime,
                                  entryImage,
                                  true,
                                  entryLat,
                                  entryLng),
                              color: Colors.teal,
                            ),
                            _buildAttendanceButton(
                              isMarked: isExitMarked,
                              label: 'Exit',
                              onMark: () =>
                                  _openCameraUI(context, false, employeeId),
                              onView: () => _navigateToViewEntry(context,
                                  exitTime, exitImage, false, exitLat, exitLng),
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Remember to mark your entry and exit daily for accurate attendance tracking.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Widget _buildAttendanceButton({
    required bool isMarked,
    required String label,
    required VoidCallback onMark,
    required VoidCallback onView,
    required Color color,
  }) {
    return SizedBox(
      width: 160,
      height: 100,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: isMarked ? onView : onMark,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isMarked ? label : 'Add $label',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Icon(
                isMarked ? Icons.visibility : Icons.add_a_photo,
                color: color,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return 'N/A';
    DateTime dateTime = DateTime.parse(isoString).toLocal();
    return DateFormat('h:mm a').format(dateTime);
  }

  String _getCurrentDate() {
    return DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
  }

  Future<void> _handleLogout() async {
    try {
      await StorageHelper.deleteUserData();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    try {
      String? userId = await StorageHelper.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      Map<String, dynamic>? userData = {
        'employeeId': userId,
        'name': userId,
        'isEntryMarked': false,
        'isExitMarked': false,
        'entry_time': '2024-01-24T09:30:00Z',
        'exit_time': '2024-01-24T17:30:00Z',
        'entry_image': 'base64EncodedImageString',
        'exit_image': 'base64EncodedImageString',
        'entry_lat': 12.9716,
        'entry_lng': 77.5946,
        'exit_lat': 12.9716,
        'exit_lng': 77.5946,
      };

      userData['employeeId'] = userId;
      return userData;
    } catch (e) {
      print('Error loading user data: $e');
      rethrow;
    }
  }

  void _navigateToViewEntry(BuildContext context, String time,
      String? base64Image, bool isEntry, double? lat, double? lng) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewEntryPage(
          time: time,
          image: base64Image,
          lat: lat,
          lng: lng,
          isEntry: isEntry,
        ),
      ),
    );
  }

  Future<void> _openCameraUI(
      BuildContext context, bool isEntry, String employeeId) async {
    try {
      final XFile? photo = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraUI(isEntry: isEntry)),
      );

      if (photo != null) {
        print('Photo captured: ${photo.path}');
        setState(() {
          _userDataFuture = _loadUserData();
        });
      }
    } catch (e) {
      print('Error opening camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open camera: $e')),
        );
      }
    }
  }
}
