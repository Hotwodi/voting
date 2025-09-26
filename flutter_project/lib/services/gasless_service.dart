import 'dart:convert';
import 'package:http/http.dart' as http;
import 'wallet_service.dart';

class GaslessService {
  static const String _relayerUrl = 'https://your-relayer-endpoint.com/relay'; // Replace with actual relayer

  static GaslessService? _instance;

  GaslessService._();

  static GaslessService get instance {
    _instance ??= GaslessService._();
    return _instance!;
  }

  // EIP-712 domain
  final Map<String, dynamic> _domain = {
    'name': 'VotingApp',
    'version': '1',
    'chainId': 137, // Polygon mainnet
    'verifyingContract': '0x...', // Contract address
  };

  // Vote message type
  final Map<String, dynamic> _voteType = {
    'Vote': [
      {'name': 'pollId', 'type': 'uint256'},
      {'name': 'optionId', 'type': 'uint256'},
      {'name': 'nonce', 'type': 'uint256'},
    ],
  };

  Future<String?> signVote(int pollId, int optionId, int nonce) async {
    final message = {
      'pollId': pollId,
      'optionId': optionId,
      'nonce': nonce,
    };

    // Use WalletConnect to sign EIP-712
    final wallet = WalletService.instance;
    final signature = await wallet.signTypedData(_domain, _voteType, message);
    return signature;
  }

  Future<String?> relayVote(int pollId, int optionId, int nonce, String signature) async {
    final payload = {
      'pollId': pollId,
      'optionId': optionId,
      'nonce': nonce,
      'signature': signature,
      'user': WalletService.instance.account,
    };

    final response = await http.post(
      Uri.parse(_relayerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['txHash'];
    }
    return null;
  }

  Future<String?> gaslessVote(int pollId, int optionId, int nonce) async {
    final signature = await signVote(pollId, optionId, nonce);
    if (signature != null) {
      return await relayVote(pollId, optionId, nonce, signature);
    }
    return null;
  }
}