import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import './permission_handler.dart';

class LocationService {
  final PermissionHandlerService _permissionService = PermissionHandlerService();

  /// Get current location with high accuracy
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location permission is granted
      bool hasPermission = await _permissionService.handleLocationPermission();
      
      if (!hasPermission) {
        // If permission permanently denied, prompt to open settings
        if (await _permissionService.isPermanentlyDenied(Permission.location)) {
          await _permissionService.openAppSettings();
        }
        return null;
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5)
        )
      );

      return position;
    } catch (e) {
      rethrow;
    }
  }
}
