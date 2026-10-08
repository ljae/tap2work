import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

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
  late final web.HTMLIFrameElement frame;
  late final JSFunction listener;
  @override
  void initState() {
    super.initState();
    frame = web.HTMLIFrameElement()
      ..src = Uri.base
          .resolve('address-search.html')
          .replace(queryParameters: {'q': widget.query})
          .toString()
      ..title = '표준 주소 검색'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    ui.platformViewRegistry.registerViewFactory(view, (_) => frame);
    listener = ((web.Event event) {
      final message = event as web.MessageEvent;
      // Native JS window identity; dart:html used different wrappers for these getters.
      if (message.origin != Uri.base.origin ||
          message.source != frame.contentWindow) {
        return;
      }
      final data = message.data.dartify();
      if (data is! String) return;
      try {
        final value = jsonDecode(data);
        if (value is Map<String, dynamic> &&
            value['type'] == 'tap-address' &&
            value['address'] is String &&
            (value['address'] as String).isNotEmpty) {
          widget.onSelected(value);
        }
      } on FormatException {
        /* Ignore unrelated provider messages. */
      }
    }).toJS;
    web.window.addEventListener('message', listener);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', listener);
    frame.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: view);
}
