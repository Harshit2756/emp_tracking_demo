import 'package:emp_tracking_demo/firebase_options.dart';
import 'package:emp_tracking_demo/ui/auth/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, //This line is necessary
  );
  runApp(const AuthWrapper());
}
