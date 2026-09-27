import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'services/local_storage_service.dart';
import 'pages/shell/main_shell_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize persistent browser local storage and seeds
  await LocalStorageService.init();

  runApp(
    const ProviderScope(
      child: CaseyaApp(),
    ),
  );
}

class CaseyaApp extends StatelessWidget {
  const CaseyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppConstants.appName} — ${AppConstants.appSubtitle}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShellPage(),
    );
  }
}
