import 'package:flutter_test/flutter_test.dart';
import '../lib/services/web3_service.dart';

void main() {
  group('Web3Service', () {
    test('instance is singleton', () {
      final service1 = Web3Service.instance;
      final service2 = Web3Service.instance;
      expect(service1, same(service2));
    });
  });
}