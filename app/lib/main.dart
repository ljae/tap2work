import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ui/cloud_workspace.dart';
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
  final sharedApi = await sharedApiForWeb();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (supabaseUrl.isNotEmpty && publishableKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: publishableKey);
    runApp(
      CloudWorkspace(
        work: controller,
        client: Supabase.instance.client,
        sharedApi: sharedApi,
      ),
    );
    return;
  }
  final operations = OperationsController(sharedApi: sharedApi);
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
  const Tap2workApp({
    super.key,
    required this.controller,
    this.operations,
    this.onAccountPressed,
    this.accountEmail,
  });
  final WorkController controller;
  final OperationsController? operations;
  final Future<void> Function(BuildContext context)? onAccountPressed;
  final String? accountEmail;
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
        indicatorColor: Colors.transparent,
        height: 70,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 25,
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.peach,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      dividerColor: AppColors.line,
    ),
    home: operations == null
        ? WorkspaceScreen(controller: controller)
        : OperationsScreen(
            operations: operations!,
            work: controller,
            onAccountPressed: onAccountPressed,
            accountEmail: accountEmail,
          ),
  );
}
