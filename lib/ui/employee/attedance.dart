import 'package:emp_tracking_demo/services/db.dart';
import 'package:emp_tracking_demo/ui/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:emp_tracking_demo/ui/employee/camera_uid.dart';
import 'package:emp_tracking_demo/ui/employee/view_entry.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:emp_tracking_demo/shared/storage_helper.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    try {
      String? userId = await StorageHelper.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final DatabaseService _db = DatabaseService();
      Map<String, dynamic>? userData = await _db.getUserById(userId);

      if (userData != null) {
        userData['employeeId'] = userId;
        return userData;
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
        throw Exception('User data not found');
      }
    } catch (e) {
      print('Error loading user data: $e');
      rethrow;
    }
  }

  String _getCurrentDate() {
    return DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return 'N/A';
    DateTime dateTime = DateTime.parse(isoString).toLocal();
    return DateFormat('h:mm a').format(dateTime);
  }

  Future<void> _openCameraUI(BuildContext context, bool isEntry, String employeeId) async {
    try {
      final XFile? photo = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraUI(isEntry: isEntry)),
      );

      if (photo != null) {
        print('Photo captured: ${photo.path}');
        await _updateAttendanceStatus(isEntry, employeeId);
        setState(() {
          _userDataFuture = _loadUserData();
        });
      }
    } catch (e) {
      print('Error opening camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open camera: $e')),
      );
    }
  }

  Future<void> _updateAttendanceStatus(bool isEntry, String employeeId) async {
    try {
      final DatabaseService _db = DatabaseService();
      await _db.updateUser(employeeId, {
        isEntry ? 'isEntryMarked' : 'isExitMarked': true,
      });
    } catch (e) {
      print('Error updating attendance status: $e');
      throw e;
    }
  }

  Future<void> _resetEntry(String employeeId) async {
    try {
      final DatabaseService _db = DatabaseService();
      await _db.updateUser(employeeId, {
        'isEntryMarked': false,
        'isExitMarked': false,
        'entry_time': null,
        'exit_time': null,
        'entry_image': null,
        'exit_image': null,
      });
      setState(() {
        _userDataFuture = _loadUserData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry reset successfully')),
      );
    } catch (e) {
      print('Error resetting entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset entry: $e')),
      );
    }
  }

  Future<void> _handleLogout() async {
    try {
      await StorageHelper.deleteUserData();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: $e')),
      );
    }
  }

  void _navigateToViewEntry(BuildContext context, String time, String? base64Image, bool isEntry, double? lat, double? lng) {
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

  Widget _buildAttendanceButton({
    required bool isMarked,
    required String label,
    required VoidCallback onMark,
    required VoidCallback onView,
    required Color color,
  }) {
    return Container(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    isMarked ? label : 'Add $label',
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  if (isMarked)
                    Icon(Icons.check_circle, color: Colors.green)
                  else
                    Icon(Icons.radio_button_unchecked, color: Colors.grey),
                ],
              ),
              SizedBox(height: 10),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal[400]!, Colors.blue[600]!],
          ),
        ),
        child: SafeArea(
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome,',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              employeeName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: _handleLogout,
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Attendance Tracker',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _getCurrentDate(),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildAttendanceButton(
                                isMarked: isEntryMarked,
                                label: 'Entry',
                                onMark: () => _openCameraUI(context, true, employeeId),
                                onView: () => _navigateToViewEntry(context, entryTime, entryImage, true, entryLat, entryLng),
                                color: Colors.teal,
                              ),
                              _buildAttendanceButton(
                                isMarked: isExitMarked,
                                label: 'Exit',
                                onMark: () => _openCameraUI(context, false, employeeId),
                                onView: () => _navigateToViewEntry(context, exitTime, exitImage, false, exitLat, exitLng),
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () => _resetEntry(employeeId),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                              shadowColor: Colors.red.withOpacity(0.5),
                            ),
                            child: const Text(
                              'Reset Entry',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
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
                        color: Colors.white.withOpacity(0.8),
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
      ),
    );
  }
}
