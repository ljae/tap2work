import 'package:flutter/foundation.dart';

const manualMediaRoot = 'https://tap2.work/manual-media/v1/';

class ManualMediaAsset {
  const ManualMediaAsset(
    this.file,
    this.kind,
    this.credit,
    this.license,
    this.source, {
    this.original,
    this.poster,
    this.scene,
  });
  final String file, kind, credit, license, source;
  final String? original, poster, scene;
  String get url => '$manualMediaRoot$file';
}

const manualMediaAssets = [
  ManualMediaAsset(
    'kitchen.jpg',
    'photo',
    'Raysonho / Open Grid Scheduler',
    'CC0 1.0',
    'https://commons.wikimedia.org/wiki/File:RestaurantKitchen.jpg',
    original: 'originals/kitchen.jpg',
  ),
  ManualMediaAsset(
    'handwashing.jpg',
    'photo',
    'Sgt. Grace L. Waladkewics / USMC',
    'Public domain (US)',
    'https://commons.wikimedia.org/wiki/File:Washing_hands_(cropped).jpg',
    original: 'originals/handwashing.jpg',
  ),
  ManualMediaAsset(
    'handwashing.mp4',
    'video',
    'CDC',
    'Public domain (US)',
    'https://commons.wikimedia.org/wiki/File:Fight_Germs._Wash_Your_Hands!.webm',
    poster: 'handwashing-poster.jpg',
  ),
  ManualMediaAsset(
    'shift.mp4',
    'motion',
    'TAP Work',
    'CC BY 4.0',
    '${manualMediaRoot}index.html#sources',
    poster: 'shift-poster.png',
    scene: 'shift',
  ),
  ManualMediaAsset(
    'opening.mp4',
    'motion',
    'TAP Work',
    'CC BY 4.0',
    '${manualMediaRoot}index.html#sources',
    poster: 'opening-poster.png',
    scene: 'opening',
  ),
  ManualMediaAsset(
    'receiving.mp4',
    'motion',
    'TAP Work',
    'CC BY 4.0',
    '${manualMediaRoot}index.html#sources',
    poster: 'receiving-poster.png',
    scene: 'receiving',
  ),
  ManualMediaAsset(
    'service.mp4',
    'motion',
    'TAP Work',
    'CC BY 4.0',
    '${manualMediaRoot}index.html#sources',
    poster: 'service-poster.png',
    scene: 'service',
  ),
  ManualMediaAsset(
    'closing.mp4',
    'motion',
    'TAP Work',
    'CC BY 4.0',
    '${manualMediaRoot}index.html#sources',
    poster: 'closing-poster.png',
    scene: 'closing',
  ),
];

ManualMediaAsset? manualMediaAsset(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'tap2.work' ||
      uri.port != 443 ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  if (isManualMotionProject(value)) {
    return const ManualMediaAsset(
      'player.html',
      'motion',
      'TAP Work · customized',
      'CC BY 4.0',
      '${manualMediaRoot}index.html#sources',
    );
  }
  return manualMediaAssets
      .where((asset) => Uri.parse(asset.url).path == uri.path)
      .firstOrNull;
}

bool isManualMotionProject(String value) {
  final uri = Uri.tryParse(value);
  return value.length <= 2000 &&
      uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'tap2.work' &&
      uri.port == 443 &&
      uri.userInfo.isEmpty &&
      uri.path == '/manual-media/v1/player.html' &&
      uri.query.isEmpty &&
      RegExp(r'^p=[A-Za-z0-9_-]{1,1900}$').hasMatch(uri.fragment);
}

bool isManualMediaKit(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'tap2.work' &&
      uri.port == 443 &&
      uri.userInfo.isEmpty &&
      const {
        '/manual-media/v1/',
        '/manual-media/v1/index.html',
      }.contains(uri.path);
}

bool hasManualMedia(Map<String, dynamic> entry) =>
    (entry['steps'] as List? ?? []).whereType<Map>().any(
      (step) =>
          manualMediaAsset('${step['imageUrl'] ?? ''}') != null ||
          manualMediaAsset('${step['videoUrl'] ?? ''}') != null,
    );

// Only this versioned, app-owned pack maps to the local web preview. Arbitrary
// external URLs and private media references keep their existing resolver.
String resolveManualMediaUrl(String value) {
  if (kIsWeb &&
      const {'localhost', '127.0.0.1'}.contains(Uri.base.host) &&
      value.startsWith(manualMediaRoot)) {
    final uri = Uri.parse(value);
    return Uri.base
        .resolveUri(
          Uri(
            path: uri.path,
            query: uri.hasQuery ? uri.query : null,
            fragment: uri.hasFragment ? uri.fragment : null,
          ),
        )
        .toString();
  }
  return value;
}
