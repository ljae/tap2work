import 'package:flutter/material.dart';
import 'components.dart';
import 'address_search_stub.dart'
    if (dart.library.html) 'address_search_web.dart'
    as platform;

class StoreAddressField extends StatefulWidget {
  const StoreAddressField({
    super.key,
    required this.controller,
    required this.onSelected,
  });
  final TextEditingController controller;
  final ValueChanged<Map<String, dynamic>?> onSelected;
  @override
  State<StoreAddressField> createState() => _StoreAddressFieldState();
}

class _StoreAddressFieldState extends State<StoreAddressField> {
  Future<void> search() async {
    final result = await showAppFormSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) => AppEditorScaffold(
        title: '표준 주소 검색',
        onClose: () => Navigator.pop(context),
        body: platform.addressSearch(
          widget.controller.text,
          (value) => Navigator.pop(context, value),
        ),
      ),
    );
    if (result == null || !mounted) return;
    widget.controller.text = result['address'] as String;
    widget.onSelected(result);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: widget.controller,
        maxLength: 200,
        decoration: const InputDecoration(
          labelText: '주소 · 선택',
          hintText: '도로명·건물명 입력 후 검색',
        ),
        onChanged: (_) => widget.onSelected(null),
        onSubmitted: (_) => search(),
      ),
      OutlinedButton.icon(
        onPressed: search,
        icon: const Icon(Icons.search),
        label: const Text('표준 주소 검색'),
      ),
    ],
  );
}
