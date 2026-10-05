import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/manual_print.dart';
import '../state/operations_controller.dart';

class ManualPdfRepository {
  Future<Uint8List> generate(
    Json snapshot,
    List<Json> sources,
    ManualPrintOptions options,
  ) async {
    if (sources.isEmpty) throw StateError('출력할 TAP을 선택해 주세요.');
    final fonts = <pw.Font>[];
    for (final name in ['Tap2workPrint', 'NotoSansSC', 'NotoSansJP']) {
      fonts.add(
        pw.Font.ttf(
          await rootBundle.load('assets/fonts/print/$name-Regular.ttf'),
        ),
      );
    }
    final font =
        fonts[options.locale == 'zh-Hans'
            ? 1
            : options.locale == 'ja'
            ? 2
            : 0];
    final pdf = pw.Document(
      title: 'tap2work ${options.format}',
      author: 'tap2work',
    );
    final labels = printLabels[options.locale]!;
    final groups = <String, List<Json>>{};
    for (final source in sources) {
      groups
          .putIfAbsent(printGroupId(source, options.groupBy), () => [])
          .add(source);
    }
    final theme = pw.ThemeData.withFont(
      base: font,
      bold: font,
      italic: font,
      boldItalic: font,
      fontFallback: fonts,
    );
    String text(dynamic value) => '${value ?? ''}'.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
      '',
    );
    pw.Widget paragraph(
      String value, {
      double size = 11,
      PdfColor color = PdfColors.black,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        text(value),
        style: pw.TextStyle(fontSize: size, color: color, lineSpacing: 3),
      ),
    );
    List<pw.Widget> paragraphs(
      String value, {
      double size = 11,
      PdfColor color = PdfColors.black,
    }) {
      final out = <pw.Widget>[];
      for (final line in value.split('\n')) {
        final runes = line.runes.toList();
        for (var start = 0; start < runes.length; start += 240) {
          out.add(
            paragraph(
              String.fromCharCodes(
                runes.sublist(start, (start + 240).clamp(0, runes.length)),
              ),
              size: size,
              color: color,
            ),
          );
        }
      }
      return out;
    }

    String pair(String translated, String original) =>
        options.locale != 'ko' && options.bilingual && translated != original
        ? '$translated\n$original'
        : translated;
    for (final group in groups.values) {
      final groupName = printGroupName(
        group.first,
        options.groupBy,
        snapshot,
        options.locale,
      );
      final groupLabel =
          labels[options.groupBy == 'part'
              ? 10
              : options.groupBy == 'zone'
              ? 11
              : 12];
      final kinds = options.format == 'both'
          ? ['checklist', 'manual']
          : [options.format];
      for (final kind in kinds) {
        final checklist = kind == 'checklist';
        pdf.addPage(
          pw.MultiPage(
            pageFormat: options.paper == 'a5'
                ? PdfPageFormat.a5
                : PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(30),
            theme: theme,
            maxPages: 1000,
            header: (c) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              padding: const pw.EdgeInsets.only(bottom: 9),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    text(snapshot['store']?['name'] ?? 'tap2work'),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${labels[checklist ? 0 : 1]} · $groupLabel',
                    style: const pw.TextStyle(fontSize: 19),
                  ),
                  pw.Text(
                    text(groupName),
                    style: const pw.TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            footer: (c) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'tap2work · ${options.locale} · R${snapshot['revision'] ?? 0}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    '${c.pageNumber} / ${c.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
            build: (c) => [
              paragraph(
                '${labels[2]}: __________________    ${labels[3]}: __________________',
                size: 10,
              ),
              for (final source in group) ...[
                pw.NewPage(freeSpace: 90),
                pw.SizedBox(height: 10),
                paragraph(
                  pair(
                    text(
                      translatedPrintContent(source, options.locale)['title'],
                    ),
                    text(source['title']),
                  ),
                  size: 15,
                ),
                if (translationState(source, options.locale) == 'missing' ||
                    translationState(source, options.locale) == 'stale')
                  paragraph(
                    '${labels[translationState(source, options.locale) == 'stale' ? 8 : 7]} · ${labels[6]} (ko)',
                    size: 9,
                    color: PdfColors.grey700,
                  ),
                if (checklist)
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey400,
                      width: .5,
                    ),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(25),
                      2: const pw.FixedColumnWidth(52),
                    },
                    children: [
                      pw.TableRow(
                        repeat: true,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                        ),
                        children: [
                          for (final v in ['#', labels[0], labels[4]])
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(7),
                              child: pw.Text(
                                v,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                      for (final (index, step) in printRows(
                        source['steps'],
                      ).indexed)
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(7),
                              child: pw.Text('${index + 1}'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(7),
                              child: pw.Text(
                                pair(
                                  text(
                                    printRows(
                                              translatedPrintContent(
                                                source,
                                                options.locale,
                                              )['steps'],
                                            )
                                            .where((s) => s['id'] == step['id'])
                                            .firstOrNull?['title'] ??
                                        step['title'],
                                  ),
                                  text(step['title']),
                                ),
                                style: const pw.TextStyle(
                                  fontSize: 11,
                                  lineSpacing: 3,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Align(
                                alignment: pw.Alignment.center,
                                child: pw.Container(
                                  width: 12,
                                  height: 12,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      color: PdfColors.grey600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  )
                else
                  for (final (index, step) in printRows(
                    source['steps'],
                  ).indexed) ...[
                    pw.NewPage(freeSpace: 75),
                    pw.SizedBox(height: 8),
                    paragraph(
                      '${index + 1}. ${pair(text(printRows(translatedPrintContent(source, options.locale)['steps']).where((s) => s['id'] == step['id']).firstOrNull?['title'] ?? step['title']), text(step['title']))}',
                      size: 13,
                    ),
                    ...paragraphs(
                      text(
                        printRows(
                                  translatedPrintContent(
                                    source,
                                    options.locale,
                                  )['steps'],
                                )
                                .where((s) => s['id'] == step['id'])
                                .firstOrNull?['manual'] ??
                            step['manual'],
                      ),
                    ),
                    if (options.bilingual &&
                        translationState(source, options.locale) ==
                            'ready') ...[
                      paragraph(
                        '${labels[6]} (ko)',
                        size: 9,
                        color: PdfColors.grey700,
                      ),
                      ...paragraphs(
                        text(step['manual']),
                        size: 10,
                        color: PdfColors.grey700,
                      ),
                    ],
                    if (text(step['tip']).isNotEmpty)
                      ...paragraphs(
                        '${labels[13]}: ${pair(text(printRows(translatedPrintContent(source, options.locale)['steps']).where((s) => s['id'] == step['id']).firstOrNull?['tip'] ?? step['tip']), text(step['tip']))}',
                        size: 10,
                      ),
                    for (final key in ['sourceUrl', 'imageUrl', 'videoUrl'])
                      if (text(step[key]).isNotEmpty)
                        ...paragraphs(
                          '${labels[14]}: ${text(step[key])}',
                          size: 8,
                          color: PdfColors.grey700,
                        ),
                  ],
                pw.SizedBox(height: 12),
                paragraph(
                  '${labels[5]}: __________________________________________________',
                  size: 10,
                ),
              ],
            ],
          ),
        );
      }
    }
    return pdf.save();
  }

  Future<bool> save(Uint8List bytes, String filename) =>
      Printing.sharePdf(bytes: bytes, filename: filename);
  Future<bool> printPdf(Uint8List bytes, String name) => Printing.layoutPdf(
    onLayout: (_) async => bytes,
    name: name,
    dynamicLayout: false,
  );
}
