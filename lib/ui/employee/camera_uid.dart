import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../services/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:emp_tracking_demo/ui/employee/submit_form.dart'; // Import the SubmitForm page

class CameraUI extends StatefulWidget {
  final bool isEntry;
  const CameraUI({super.key, required this.isEntry});

  @override
  State<CameraUI> createState() => _CameraUIState();
}

class _CameraUIState extends State<CameraUI> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isFrontCamera = false;
  bool _isTorchOn = false;
  bool _hasCameraPermission = false;
  final PermissionHandlerService _permissionService = PermissionHandlerService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _checkAndRequestCameraPermission();
    if (_hasCameraPermission) {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras[_isFrontCamera ? 1 : 0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _checkAndRequestCameraPermission() async {
    bool hasPermission = await _permissionService.handleCameraPermission();
    setState(() {
      _hasCameraPermission = hasPermission;
    });
    if (hasPermission) {
      // _showPermissionStatus('Camera permission is allowed');
    } else {
      _showPermissionStatus('Camera permission is not allowed');
      await _requestCameraPermission();
    }
  }

  Future<void> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _hasCameraPermission = true;
      });
      _showPermissionStatus('Camera permission granted');
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    } else {
      _showPermissionStatus('Camera permission denied');
    }
  }

  void _showPermissionStatus(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text('This app needs camera access to take pictures. Please grant camera permission in settings to continue.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to previous screen
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _permissionService.openAppSettings();
                await _checkAndRequestCameraPermission(); // Check again after returning from settings
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _takePicture() async {
    if (!_hasCameraPermission || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      if (mounted) {
        // Pass both photo and isEntry to SubmitForm
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SubmitForm(
              photo: photo,
              isEntry: widget.isEntry,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_controller?.value.isInitialized ?? false)
              Center(
                child: CameraPreview(_controller!),
              ),
            
            // Bottom controls
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios),
                    color: Colors.white,
                    iconSize: 32,
                    onPressed: () async {
                      setState(() {
                        _isFrontCamera = !_isFrontCamera;
                      });
                      // await _controller?.dispose();
                      _controller = CameraController(
                        _cameras[_isFrontCamera ? 1 : 0],
                        ResolutionPreset.high,
                        enableAudio: false,
                      );
                      await _controller!.initialize();
                      if (mounted) setState(() {});
                    },
                  ),
                  
                  // Capture button
                  FloatingActionButton(
                    onPressed: _takePicture,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.camera, color: Colors.black, size: 32),
                  ),

                  // Torch button (only show for rear camera)
                  IconButton(
                    icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
                    color: _isFrontCamera ? Colors.grey : Colors.white,
                    iconSize: 32,
                    onPressed: _isFrontCamera 
                      ? null 
                      : () async {
                          setState(() {
                            _isTorchOn = !_isTorchOn;
                          });
                          await _controller?.setFlashMode(
                            _isTorchOn ? FlashMode.torch : FlashMode.off
                          );
                        },
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
