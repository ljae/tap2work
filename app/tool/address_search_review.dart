import 'package:flutter/material.dart';
import 'package:tap2work/ui/address_search.dart';

void main() => runApp(const MaterialApp(home: AddressReview()));

class AddressReview extends StatefulWidget {
  const AddressReview({super.key});
  @override
  State<AddressReview> createState() => _AddressReviewState();
}

class _AddressReviewState extends State<AddressReview> {
  final controller = TextEditingController(text: '세종대로 110');
  Map<String, dynamic>? selected;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StoreAddressField(
              controller: controller,
              onSelected: (value) => setState(() => selected = value),
            ),
            Text(
              selected == null
                  ? '선택 전'
                  : '선택 완료: ${selected!['address']} / ${selected!['zonecode']}',
            ),
          ],
        ),
      ),
    ),
  );
}
