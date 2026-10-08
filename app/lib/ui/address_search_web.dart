// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

Widget addressSearch(
  String query,
  ValueChanged<Map<String, dynamic>> onSelected,
) => _AddressSearch(query: query, onSelected: onSelected);

class _AddressSearch extends StatefulWidget {
  const _AddressSearch({required this.query, required this.onSelected});
  final String query;
  final ValueChanged<Map<String, dynamic>> onSelected;
  @override
  State<_AddressSearch> createState() => _AddressSearchState();
}

class _AddressSearchState extends State<_AddressSearch> {
  static int serial = 0;
  late final String view = 'store-address-${serial++}';
  late final html.IFrameElement frame;
  StreamSubscription<html.MessageEvent>? subscription;
  @override
  void initState() {
    super.initState();
    frame = html.IFrameElement()
      ..src = Uri.base
          .resolve('address-search.html')
          .replace(queryParameters: {'q': widget.query})
          .toString()
      ..title = '표준 주소 검색'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    ui.platformViewRegistry.registerViewFactory(view, (_) => frame);
    subscription = html.window.onMessage.listen((event) {
      if (event.origin != Uri.base.origin ||
          event.source != frame.contentWindow ||
          event.data is! String) {
        return;
      }
      try {
        final value = jsonDecode(event.data as String);
        if (value is Map<String, dynamic> &&
            value['type'] == 'tap-address' &&
            value['address'] is String &&
            (value['address'] as String).isNotEmpty) {
          widget.onSelected(value);
        }
      } on FormatException {
        /* Ignore unrelated provider messages. */
      }
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    frame.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: view);
}
