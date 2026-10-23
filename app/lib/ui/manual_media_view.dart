import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/manual_media_assets.dart';
import '../l10n/app_localizations.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'place_guide.dart';
import 'manual_video_stub.dart'
    if (dart.library.js_interop) 'manual_video_web.dart'
    as platform;

Future<void> openManualMediaLink(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
  try {
    if (await launchUrl(
      Uri.parse(resolveManualMediaUrl(value)),
      mode: LaunchMode.externalApplication,
    )) {
      return;
    }
  } catch (_) {
    /* Keep the reader/editor and its draft open on failure. */
  }
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t('ui.audit678'))));
  }
}

class ManualMediaView extends StatelessWidget {
  const ManualMediaView({
    super.key,
    required this.step,
    this.ops,
    this.showPhoto = true,
  });
  final Json step;
  final OperationsController? ops;
  final bool showPhoto;

  @override
  Widget build(BuildContext context) {
    final photo = '${step['imageUrl'] ?? ''}',
        video = '${step['videoUrl'] ?? ''}',
        source = '${step['sourceUrl'] ?? ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPhoto && photo.isNotEmpty) ...[
          const SizedBox(height: 16),
          placePhoto(resolveManualMediaUrl(photo), ops: ops),
        ],
        if (manualMediaAsset(photo) case final asset?) _Credit(asset: asset),
        if (manualMediaAsset(photo) == null &&
            Uri.tryParse(photo)?.scheme == 'https')
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => openManualMediaLink(context, photo),
              icon: const Icon(Icons.open_in_new),
              label: Text(context.t('manual.openPhoto')),
            ),
          ),
        if (Uri.tryParse(video)?.scheme == 'https') ...[
          const SizedBox(height: 16),
          _Video(key: ValueKey(video), url: video),
        ],
        if (Uri.tryParse(source)?.scheme == 'https')
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => openManualMediaLink(context, source),
              icon: Icon(
                isManualMediaKit(source)
                    ? Icons.folder_zip_outlined
                    : Icons.open_in_new,
              ),
              label: Text(
                context.t(
                  isManualMediaKit(source) ? 'media.sourceKit' : 'media.source',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Credit extends StatelessWidget {
  const _Credit({required this.asset});
  final ManualMediaAsset asset;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${asset.credit} · ${asset.license}', style: AppText.caption),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => openManualMediaLink(context, asset.source),
              child: Text(context.t('media.source')),
            ),
            if (asset.original != null)
              TextButton(
                onPressed: () => openManualMediaLink(
                  context,
                  '$manualMediaRoot${asset.original}',
                ),
                child: Text(context.t('media.download')),
              ),
            if (asset.scene != null)
              TextButton.icon(
                onPressed: () => openManualMediaLink(
                  context,
                  '${manualMediaRoot}studio.html?scene=${asset.scene}',
                ),
                icon: const Icon(Icons.edit_outlined, color: AppColors.accent),
                label: Text(context.t('media.editMotion')),
              ),
          ],
        ),
      ],
    ),
  );
}

class _Video extends StatefulWidget {
  const _Video({super.key, required this.url});
  final String url;
  @override
  State<_Video> createState() => _VideoState();
}

class _VideoState extends State<_Video> {
  bool opened = false, failed = false;
  int attempt = 0;
  @override
  Widget build(BuildContext context) {
    final asset = manualMediaAsset(widget.url);
    final motion = isManualMotionProject(widget.url);
    final direct =
        motion ||
        RegExp(
          r'\.(mp4|webm|m4v|mov)$',
          caseSensitive: false,
        ).hasMatch(Uri.parse(widget.url).path);
    final label = context.t(
      asset?.kind == 'motion' ? 'media.motion' : 'media.video',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kIsWeb && direct && opened && !failed)
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: constraints.maxWidth * 9 / 16 + (motion ? 150 : 0),
              child: KeyedSubtree(
                key: ValueKey((widget.url, attempt)),
                child: platform.manualVideo(
                  resolveManualMediaUrl(widget.url),
                  label,
                  () {
                    if (mounted) setState(() => failed = true);
                  },
                  motion: motion,
                ),
              ),
            ),
          )
        else if (!opened && asset?.poster != null)
          Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: placePhoto(
                  resolveManualMediaUrl('$manualMediaRoot${asset!.poster}'),
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (kIsWeb && direct) {
                    setState(() => opened = true);
                  } else {
                    openManualMediaLink(context, widget.url);
                  }
                },
                icon: const Icon(Icons.play_circle_outline),
                label: Text('$label · ${context.t('media.open')}'),
              ),
            ],
          ),
        if (failed) Information(context.t('media.failed')),
        Wrap(
          spacing: 8,
          children: [
            if (kIsWeb && direct && (!opened || failed))
              TextButton.icon(
                onPressed: () => setState(() {
                  opened = true;
                  failed = false;
                  attempt++;
                }),
                icon: Icon(failed ? Icons.refresh : Icons.play_circle_outline),
                label: Text(context.t(failed ? 'common.retry' : 'media.open')),
              ),
            TextButton.icon(
              onPressed: () => openManualMediaLink(context, widget.url),
              icon: const Icon(Icons.open_in_new),
              label: Text(context.t('media.external')),
            ),
          ],
        ),
        if (asset != null) _Credit(asset: asset),
        if (motion)
          TextButton.icon(
            onPressed: () => openManualMediaLink(
              context,
              Uri.parse(
                widget.url,
              ).replace(path: '/manual-media/v1/studio.html').toString(),
            ),
            icon: const Icon(Icons.edit_outlined, color: AppColors.accent),
            label: Text(context.t('media.editMotion')),
          ),
      ],
    );
  }
}
