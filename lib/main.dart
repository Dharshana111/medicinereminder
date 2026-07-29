import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medreminder/app/app.dart';
import 'package:medreminder/services/storage_service.dart';
import 'package:medreminder/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  await StorageService.init();
  await NotificationService.init();
  NotificationService.scheduleVoiceAlerts();

  runApp(const MedCareApp());
}
