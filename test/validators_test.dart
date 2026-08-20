import 'package:flutter_test/flutter_test.dart';
import 'package:full_ride_flow_task/core/utils/formatters.dart';
import 'package:full_ride_flow_task/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts a well-formed address', () {
      expect(Validators.email('rider@vybecabs.com'), isNull);
    });

    test('rejects empty and malformed addresses', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('rider@'), isNotNull);
      expect(Validators.email('rider.vybecabs.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('requires at least six characters', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Formatters.countdown', () {
    test('formats seconds as m:ss', () {
      expect(Formatters.countdown(0), '0:00');
      expect(Formatters.countdown(65), '1:05');
      expect(Formatters.countdown(240), '4:00');
    });

    test('never renders a negative countdown', () {
      expect(Formatters.countdown(-30), '0:00');
    });
  });
}
