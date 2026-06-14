import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/subjects/presentation/pages/subjects_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Zainicjuj lokalizację polską dla DateFormat
  await initializeDateFormatting('pl_PL', null);

  // Wymuszamy orientację pionową na urządzeniach mobilnych
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // DI: rejestracja wszystkich zależności (singletony i factory)
  await initDependencies();

  runApp(const LekturAIApp());
}

class LekturAIApp extends StatelessWidget {
  const LekturAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LekturAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const SubjectsPage(),
    );
  }
}
