import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'components.dart';

const privacyContact = 'esther.runstrict@gmail.com';

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
              const Expanded(child: Text('개인정보처리방침', style: AppText.section)),
              IconButton(
                tooltip: '닫기',
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
                return const Center(child: Text('안내를 열지 못했어요. 다시 열어 주세요.'));
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
                          const SnackBar(content: Text('이메일 주소를 복사해 문의해 주세요.')),
                        );
                      }
                    },
                    child: const Text('개인정보 문의하기'),
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
