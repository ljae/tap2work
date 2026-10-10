import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tap2work/data/photo_capture_service.dart';
import 'package:tap2work/ui/photo_registration.dart';

class PendingCapture extends PhotoCaptureService {
  final next = Completer<OptimizedPhoto?>();
  PhotoSource? source;
  @override
  bool get supportsCamera => true;
  @override
  Future<OptimizedPhoto?> pick(PhotoSource value) {
    source = value;
    return next.future;
  }
}

OptimizedPhoto fixture() => OptimizedPhoto(
  bytes: img.encodeJpg(img.Image(width: 50, height: 30)),
  width: 50,
  height: 30,
);

void main() {
  testWidgets('capture primary, cancellation keeps existing and clears busy', (
    t,
  ) async {
    final service = PendingCapture();
    final events = <bool>[];
    OptimizedPhoto? changed;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotoRegistrationField(
            value: 'old',
            onChanged: (p) => changed = p,
            onRemove: () {},
            scopeKey: 'draft',
            isScopeCurrent: () => true,
            service: service,
            onBusyChanged: events.add,
            previewBuilder: (_) => const Text('기존 사진'),
          ),
        ),
      ),
    );
    await t.tap(find.text('다시 사진 찍기'));
    await t.pump();
    expect(service.source, PhotoSource.camera);
    expect(find.text('기존 사진'), findsOneWidget);
    expect(find.text('사진을 준비하고 있어요…'), findsOneWidget);
    service.next.complete(null);
    await t.pump();
    expect(changed, isNull);
    expect(events, [true, false]);
    expect(find.text('기존 사진'), findsOneWidget);
  });

  testWidgets('changed actor/workspace cannot consume pending camera result', (
    t,
  ) async {
    final service = PendingCapture();
    var current = true;
    OptimizedPhoto? changed;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotoRegistrationField(
            value: '',
            onChanged: (p) => changed = p,
            onRemove: () {},
            scopeKey: 'actor/workspace/step',
            isScopeCurrent: () => current,
            service: service,
          ),
        ),
      ),
    );
    await t.tap(find.text('바로 사진 찍기'));
    current = false;
    service.next.complete(fixture());
    await t.pump();
    expect(changed, isNull);
    expect(find.textContaining('다시 열어 주세요'), findsOneWidget);
  });

  testWidgets('remove supersedes conversion job and cannot restore photo', (
    t,
  ) async {
    final service = PendingCapture();
    var changed = 0, removed = 0;
    final events = <bool>[];
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotoRegistrationField(
            value: 'old',
            onChanged: (_) => changed++,
            onRemove: () => removed++,
            scopeKey: 'draft',
            isScopeCurrent: () => true,
            service: service,
            onBusyChanged: events.add,
            previewBuilder: (_) => const Text('기존 사진'),
          ),
        ),
      ),
    );
    await t.tap(find.text('앨범에서 선택'));
    await t.pump();
    await t.tap(find.text('사진 제거'));
    await t.pump();
    service.next.complete(fixture());
    await t.pump();
    expect(changed, 0);
    expect(removed, 1);
    expect(events, [true, false]);
  });

  testWidgets('permission error retains photo, disposed jobs never write', (
    t,
  ) async {
    final service = PendingCapture();
    var changes = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotoRegistrationField(
            value: 'old',
            onChanged: (_) => changes++,
            onRemove: () {},
            scopeKey: 'draft',
            isScopeCurrent: () => true,
            service: service,
            previewBuilder: (_) => const Text('기존 사진'),
          ),
        ),
      ),
    );
    await t.tap(find.text('앨범에서 선택'));
    service.next.completeError(const PhotoException('기기 설정에서 사진 권한을 허용해 주세요.'));
    await t.pump();
    expect(find.text('기존 사진'), findsOneWidget);
    expect(find.textContaining('사진 권한'), findsOneWidget);
    expect(changes, 0);

    final next = PendingCapture();
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotoRegistrationField(
            key: const ValueKey('new'),
            value: '',
            onChanged: (_) => changes++,
            onRemove: () {},
            scopeKey: 'next',
            isScopeCurrent: () => true,
            service: next,
          ),
        ),
      ),
    );
    await t.tap(find.text('바로 사진 찍기'));
    await t.pumpWidget(const SizedBox());
    next.next.complete(fixture());
    await t.pump();
    expect(changes, 0);
    expect(t.takeException(), isNull);
  });
}
