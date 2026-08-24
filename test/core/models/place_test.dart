import 'package:flutter_test/flutter_test.dart';
import 'package:jejuflow/core/models/place.dart';

void main() {
  group('TourPlace.looksLikeCafe', () {
    TourPlace place({String title = '', String cat3 = ''}) => TourPlace(
          contentId: '1',
          contentTypeId: '39',
          title: title,
          addr: '',
          tel: '',
          imageUrl: '',
          thumbUrl: '',
          cat3: cat3,
        );

    test('recognizes the TourAPI cafe category', () {
      expect(place(title: '테스트', cat3: 'A05020900').looksLikeCafe, isTrue);
    });

    test('recognizes Korean and translated cafe names', () {
      expect(place(title: '애월 커피').looksLikeCafe, isTrue);
      expect(place(title: 'Seaside Bakery').looksLikeCafe, isTrue);
      expect(place(title: '海辺カフェ').looksLikeCafe, isTrue);
    });

    test('does not classify a regular restaurant as a cafe', () {
      expect(place(title: '성산 흑돼지 식당').looksLikeCafe, isFalse);
    });
  });
}
