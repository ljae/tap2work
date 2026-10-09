import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tap2work/ui/cloud_workspace.dart';
import 'package:tap2work/state/work_controller.dart';
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture responsive login design', (tester) async {
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        'https://example.supabase.co',
        'public',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    ))!;
    addTearDown(() => tester.runAsync(client.dispose));
    final work = WorkController(MemoryStore());
    addTearDown(work.dispose);
    final key = GlobalKey();
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dir = Directory('../.local/login-design-review')
      ..createSync(recursive: true);
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${dir.path}/$name.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: CloudWorkspace(
          work: work,
          client: client,
          loadProviders: () async => {
            OAuthProvider.google,
            OAuthProvider.apple,
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    await capture('login');
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    await capture('login-desktop');
  });
}
