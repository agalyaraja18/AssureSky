import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/theme_bloc.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
