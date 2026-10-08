import 'dart:convert';
import 'dart:io';
import 'package:tap2work/state/operations_controller.dart';

Json setupCatalogFixture() {
  final release =
      jsonDecode(File('../docs/market/current.json').readAsStringSync())
          as Json;
  return {
    ...release,
    'businessTypes': [
      {
        'id': 'chicken',
        'name': '치킨',
        'industryId': 'restaurant',
        'collectionId': 'chicken',
      },
      {
        'id': 'korean',
        'name': '한식',
        'industryId': 'restaurant',
        'collectionId': 'korean',
      },
      {
        'id': 'donkatsu',
        'name': '돈까스',
        'industryId': 'restaurant',
        'collectionId': 'chicken',
      },
      {
        'id': 'cafe',
        'name': '카페',
        'industryId': 'cafe',
        'collectionId': 'cafe',
      },
    ],
    'purposes': release['taxonomy']['purposes'],
  };
}
