import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web_socket_channel/io.dart';

class Web3Service {
  static final Web3Service instance = Web3Service._internal();
  Web3Client? _client;

  // TODO: Replace with your Alchemy API key
  // Alchemy API key (provided by user)
  // Keep this secret in production; use secure storage or environment variables for CI/CD.
  static const String _alchemyApiKey = 'y6RsMlq62mXqDZC08T_6S';
  static const String _httpUrl = 'https://polygon-mainnet.g.alchemy.com/v2/$_alchemyApiKey';
  // WebSocket URL for event subscriptions (optional)
  static const String _wssUrl = 'wss://polygon-mainnet.g.alchemy.com/v2/$_alchemyApiKey';

  Web3Service._internal();

  void init() {
    _client = Web3Client(_httpUrl, Client());
  }

  /// Initialize a WebSocket-backed client for subscriptions
  Web3Client newWebSocketClient() {
    final socketConnector = () {
      return IOWebSocketChannel.connect(_wssUrl).cast<String>();
    };
    return Web3Client(_wssUrl, Client(), socketConnector: socketConnector);
  }

  Future<int> getLatestBlockNumber() async {
    _client ??= Web3Client(_httpUrl, Client());
    final bn = await _client!.getBlockNumber();
    return bn.toInt();
  }

  DeployedContract loadContract(String abiJson, String contractAddress, String name) {
    final contract = DeployedContract(ContractAbi.fromJson(abiJson, name), EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> callFunction(DeployedContract contract, String functionName, List<dynamic> params) async {
    final function = contract.function(functionName);
    final result = await _client!.call(contract: contract, function: function, params: params);
    return result;
  }

  /// Encode a contract function call and return 0x-prefixed hex data string
  String encodeFunctionCall(String abiJson, String contractAddress, String functionName, List<dynamic> params) {
    final contract = DeployedContract(ContractAbi.fromJson(abiJson, 'Contract'), EthereumAddress.fromHex(contractAddress));
    final function = contract.function(functionName);
    final encoded = function.encodeCall(params);
    return bytesToHex(encoded, include0x: true);
  }

  /// Subscribe to contract events using a WebSocket client.
  /// Returns the Stream<FilterEvent> you can listen to.
  Stream<FilterEvent> listenToEvent({
    required String abiJson,
    required String contractAddress,
    required String eventName,
  }) {
    final wsClient = newWebSocketClient();
    final contract = DeployedContract(ContractAbi.fromJson(abiJson, 'Contract'), EthereumAddress.fromHex(contractAddress));
    final event = contract.event(eventName);
    final filter = FilterOptions.events(contract: contract, event: event);
    return wsClient.events(filter);
  }
}
