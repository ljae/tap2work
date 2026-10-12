import '../l10n/app_localizations.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'components.dart';

const privacyContact = 'tap2work.dev@gmail.com';

Future<void> openPrivacy(BuildContext context) =>
    showAppSheet<void>(context, builder: (_) => const PrivacyScreen());

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late final policy = rootBundle.loadString('assets/legal/privacy.json');
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(context.t('ui.audit168'), style: AppText.section),
              ),
              IconButton(
                tooltip: context.t('ui.audit83'),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<String>(
            future: policy,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(context.t('ui.audit1059')));
              }
              if (!snapshot.hasData) {
                return const Center(child: AppCircularProgress());
              }
              final data = jsonDecode(snapshot.data!) as Map;
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                children: [
                  Text(
                    '${data['operator']} · ${data['effectiveDate']}',
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 24),
                  for (final section in data['sections'] as List) ...[
                    Text(section['title'] as String, style: AppText.section),
                    const SizedBox(height: 12),
                    SelectableText(
                      (section['paragraphs'] as List).join('\n\n'),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const SelectableText(privacyContact),
                  TextButton(
                    onPressed: () async {
                      final opened = await launchUrl(
                        Uri(scheme: 'mailto', path: privacyContact),
                      );
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.t('ui.audit1060'))),
                        );
                      }
                    },
                    child: Text(context.t('ui.audit472')),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
