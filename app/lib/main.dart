import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'domain/shared_api.dart';
import 'state/work_controller.dart';
import 'state/operations_controller.dart';
import 'ui/operations_screen.dart';
import 'ui/workspace_screen.dart';
import 'ui/components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = WorkController(DeviceProgressStore());
  await controller.initialize();
  final operations = OperationsController(sharedApi: await sharedApiForWeb());
  runApp(Tap2workApp(controller: controller, operations: operations));
  operations.start();
}

const _sharedApiKey = 'tap2work.sharedApi';

/// Public web builds may connect to an owner's tunnelled demo server via `?api=`;
/// the address is remembered in this browser until `?api=off`.
Future<String?> sharedApiForWeb() async {
  if (!kIsWeb || !const bool.fromEnvironment('PUBLIC_REVIEW')) return null;
  try {
    final prefs = await SharedPreferences.getInstance();
    final resolved = resolveSharedApi(
      base: Uri.base,
      stored: prefs.getString(_sharedApiKey),
    );
    if (resolved == null) {
      if (sharedApiCleared(Uri.base)) await prefs.remove(_sharedApiKey);
    } else {
      await prefs.setString(_sharedApiKey, resolved);
    }
    return resolved;
  } catch (_) {
    return null;
  }
}

class Tap2workApp extends StatelessWidget {
  const Tap2workApp({super.key, required this.controller, this.operations});
  final WorkController controller;
  final OperationsController? operations;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'tap2work',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ko', 'KR'),
    supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      fontFamily: 'NotoSansKR',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.muted,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.accent.withValues(alpha: .10),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
      ),
      dividerColor: AppColors.line,
    ),
    home: operations == null
        ? WorkspaceScreen(controller: controller)
        : OperationsScreen(operations: operations!, work: controller),
  );
}
