import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/background_tasks.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme_bloc.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Notifications are an enhancement: if setup fails the app must still start.
  try {
    await NotificationService.init();
    // Schedules the hourly background weather check (Android only).
    unawaited(BackgroundTasks.register()
        .catchError((Object e) => debugPrint('Background task error: $e')));
  } catch (e) {
    debugPrint('Notification setup error: $e');
  }

  runApp(const AssureSkyApp());
}

class AssureSkyApp extends StatelessWidget {
  const AssureSkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeBloc()..add(ThemeLoaded()),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'AssureSky',
            debugShowCheckedModeBanner: false,
            theme: themeState.themeData,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
