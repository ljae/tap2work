import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'state/work_controller.dart';
import 'state/operations_controller.dart';
import 'ui/operations_screen.dart';
import 'ui/workspace_screen.dart';
import 'ui/components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = WorkController(DeviceProgressStore());
  await controller.initialize();
  final operations = OperationsController();
  runApp(Tap2workApp(controller: controller, operations: operations));
  operations.start();
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
        seedColor: AppColors.green,
        primary: AppColors.green,
        surface: AppColors.paper,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.lime.withValues(alpha: .5),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
      ),
      dividerColor: AppColors.line,
    ),
    home: operations == null
        ? WorkspaceScreen(controller: controller)
        : OperationsScreen(operations: operations!, work: controller),
  );
}
