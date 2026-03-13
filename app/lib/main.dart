import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'app/app_bloc_observer.dart';
import 'app/dependency_injection.dart';
import 'core/services/background_task_runner.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Setup dependency injection
  await configureDependencies();

  // Setup BLoC observer for debugging
  Bloc.observer = AppBlocObserver();

  // Khởi tạo notification
  await NotificationService.init();
  await NotificationService.requestPermission();

  // Xin quyền location rồi đăng ký background tasks
  final locationGranted = await LocationService().requestPermission();
  if (locationGranted) {
    try {
      await Workmanager().initialize(callbackDispatcher);
      await registerBackgroundTasks();
    } catch (e) {
      debugPrint('⚠️ Background task registration failed: $e');
    }
    // Lên lịch nhắc nhở hàng ngày (kể cả khi app không chạy)
    await NotificationService.scheduleCheckInReminder();
    await NotificationService.scheduleCheckOutReminder();
  }

  runApp(const App());
}

