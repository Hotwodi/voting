import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WalletService', () {
    test('saveConfig and loadConfig', () async {
      SharedPreferences.setMockInitialValues({});
      final service = WalletService.instance;

      await service.saveConfig(abiJson: '{"test": "abi"}', contractAddress: '0x123');
      final config = await service.loadConfig();
      expect(config['abiJson'], '{"test": "abi"}');
      expect(config['contractAddress'], '0x123');
    });
  });
}