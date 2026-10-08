import 'dart:convert';
import 'dart:io';
import 'package:tap2work/state/operations_controller.dart';

Json setupCatalogFixture() {
  final release =
      jsonDecode(File('../docs/market/current.json').readAsStringSync())
          as Json;
  return {
    ...release,
    'bundleVersion': 'test-bundle-v1',
    'bundles': {
      'donkatsu': [
        {
          'id': 'donkatsu-1',
          'name': '등심 돈까스',
          'ingredients': ['돼지등심', '빵가루'],
          'method': '매장 기준으로 튀김옷을 입혀 조리해요.',
        },
        {
          'id': 'donkatsu-2',
          'name': '치즈 돈까스',
          'ingredients': ['돼지등심', '치즈'],
          'method': '치즈를 넣고 매장 기준으로 조리해요.',
        },
      ],
    },
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
