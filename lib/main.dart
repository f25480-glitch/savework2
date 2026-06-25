import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'l10n/app_strings.dart';
import 'screens/main_shell.dart';
import 'services/work_day_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th');

  final storage = WorkDayStorage();
  await storage.init();

  runApp(WorkDayApp(storage: storage));
}

class WorkDayApp extends StatelessWidget {
  const WorkDayApp({super.key, required this.storage});

  final WorkDayStorage storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MainShell(storage: storage),
    );
  }
}
