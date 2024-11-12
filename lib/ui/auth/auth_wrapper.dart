import 'package:emp_tracking_demo/services/permission_handler.dart';
import 'package:emp_tracking_demo/shared/storage_helper.dart';
import 'package:emp_tracking_demo/ui/auth/login.dart';
import 'package:emp_tracking_demo/ui/employee/attedance.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final PermissionHandlerService _permissionService =
      PermissionHandlerService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: StorageHelper.isUserLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final bool isLoggedIn = snapshot.data ?? false;

          if (isLoggedIn) {
            return const AttendancePage(); // You'll need to create this
          } else {
            return const LoginPage(); // You'll need to create this
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    Map<Permission, bool> permissions =
        await _permissionService.handleRequiredPermissions();

    if (!permissions[Permission.camera]! ||
        !permissions[Permission.location]!) {
      // If permissions are permanently denied, open app settings
      if (await _permissionService.isPermanentlyDenied(Permission.camera) ||
          await _permissionService.isPermanentlyDenied(Permission.location)) {
        await _permissionService.openAppSettings();
      }
    }
  }
}
