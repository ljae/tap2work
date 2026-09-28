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
      brightness: Brightness.dark,
      fontFamily: 'Pretendard',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.primary,
        primary: AppColors.green,
        onPrimary: AppColors.paper,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.muted,
        outline: AppColors.controlLine,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: const TextTheme(
        headlineSmall: AppText.title,
        headlineMedium: AppText.title,
        titleLarge: AppText.title,
        titleMedium: AppText.body,
        titleSmall: AppText.body,
        bodyMedium: AppText.body,
        bodyLarge: AppText.body,
        bodySmall: AppText.caption,
        labelLarge: AppText.body,
        labelMedium: AppText.caption,
        labelSmall: AppText.caption,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Color(0x0A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        titleSpacing: 24,
        titleTextStyle: AppText.title,
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.green,
          side: const BorderSide(color: AppColors.controlLine),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.green),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
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
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 13)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.elevated,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.lime,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        showCheckmark: false,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        dragHandleColor: AppColors.controlLine,
        dragHandleSize: Size(32, 4),
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: const WidgetStatePropertyAll(BorderSide.none),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.paper
                : AppColors.muted,
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.paper
              : AppColors.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.elevated,
        ),
      ),
      dividerColor: AppColors.line,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.green,
        contentTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          color: AppColors.surface,
          fontSize: 13,
        ),
        behavior: SnackBarBehavior.floating,
      ),
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
