import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'web3_service.dart';

class WalletService {
  static final WalletService instance = WalletService._internal();
  WalletConnect? _connector;
  SessionStatus? _session;
  String? account;

  WalletService._internal();

  Future<void> init() async {
    _connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
        name: 'Polygon Voting App',
        description: 'Secure voting using Polygon blockchain',
        url: 'https://yourdomain.com',
        icons: ['https://yourdomain.com/icon.png'],
      ),
    );

    _connector!.on('connect', (session) {
      // ignore: avoid_print
      print('Wallet connected: $session');
    });

    _connector!.on('session_update', (payload) {
      // ignore: avoid_print
      print('Session updated: $payload');
    });

    _connector!.on('disconnect', (session) {
      // ignore: avoid_print
      print('Disconnected');
      account = null;
    });
  }

  Future<void> connect() async {
    if (_connector == null) await init();

    if (!_connector!.connected) {
      final session = await _connector!.createSession(onDisplayUri: (uri) async {
        await launchUrlString(uri, mode: LaunchMode.externalApplication);
      });
      _session = session;
      if (session.accounts.isNotEmpty) {
        account = session.accounts.first;
      }
    } else {
      account = _connector!.session.accounts.first;
    }
  }

  Future<String?> sendTransaction(Map<String, dynamic> tx) async {
    if (_connector == null || !_connector!.connected) {
      throw Exception('Wallet not connected');
    }
    final result = await _connector!.sendCustomRequest(method: 'eth_sendTransaction', params: [tx]);
    return result as String?;
  }

  /// Helper to send a contract function call via WalletConnect.
  ///
  /// Example: sendContractTransaction(abiJson, contractAddress, 'vote', [BigInt.from(1)])
  Future<String?> sendContractTransaction({
    required String abiJson,
    required String contractAddress,
    required String functionName,
    required List<dynamic> functionParams,
    String? fromAddress,
  }) async {
    if (_connector == null || !_connector!.connected) {
      throw Exception('Wallet not connected');
    }

    // Use Web3Service to encode the function call
    final data = Web3Service.instance.encodeFunctionCall(abiJson, contractAddress, functionName, functionParams);

    final from = fromAddress ?? account;
    if (from == null) throw Exception('No account available');

    final tx = {
      'from': from,
      'to': contractAddress,
      'data': data,
      // Polygon mainnet chain id (decimal 137 -> hex 0x89)
      'chainId': '0x89',
    };

    final result = await _connector!.sendCustomRequest(method: 'eth_sendTransaction', params: [tx]);
    return result as String?;
  }
}
