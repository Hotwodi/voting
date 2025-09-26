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

  /// Robust event subscription with reconnect/backoff. Returns a stream that
  /// attempts to reconnect when the underlying WS closes and falls back to
  /// polling by invoking [pollCallback] on the given interval if WS is down.
  Stream<dynamic> subscribeWithFallback({
    required String abiJson,
    required String contractAddress,
    required String eventName,
    Duration reconnectDelay = const Duration(seconds: 2),
    Duration maxDelay = const Duration(seconds: 30),
    Duration pollInterval = const Duration(seconds: 15),
    Future<void> Function()? pollCallback,
  }) async* {
    var delay = reconnectDelay;
    while (true) {
      try {
        final wsClient = newWebSocketClient();
        final contract = DeployedContract(ContractAbi.fromJson(abiJson, 'Contract'), EthereumAddress.fromHex(contractAddress));
        final event = contract.event(eventName);
        final filter = FilterOptions.events(contract: contract, event: event);
        await for (final ev in wsClient.events(filter)) {
          yield ev;
        }
        // If we exit the loop, connection closed — try reconnect
        await Future.delayed(delay);
        delay = (delay * 2) < maxDelay ? (delay * 2) : maxDelay;
      } catch (e) {
        // WS failed — run poll fallback if provided, then wait and retry
        if (pollCallback != null) {
          try {
            await pollCallback();
          } catch (pollErr) {
            // ignore poll errors
          }
        }
        await Future.delayed(delay);
        delay = (delay * 2) < maxDelay ? (delay * 2) : maxDelay;
      }
    }
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
  Stream<dynamic> listenToEvent({
    required String abiJson,
    required String contractAddress,
    required String eventName,
  }) {
    final wsClient = newWebSocketClient();
    final contract = DeployedContract(ContractAbi.fromJson(abiJson, 'Contract'), EthereumAddress.fromHex(contractAddress));
    final event = contract.event(eventName);
    final filter = FilterOptions.events(contract: contract, event: event);
    // Stream of FilterEvent objects; we'll decode them in the UI layer.
    return wsClient.events(filter);
  }

  /// Decode a FilterEvent into event parameters using the contract ABI
  Map<String, dynamic> decodeEvent({required String abiJson, required String contractAddress, required String eventName, required FilterEvent event}) {
    final contract = DeployedContract(ContractAbi.fromJson(abiJson, 'Contract'), EthereumAddress.fromHex(contractAddress));
    final ev = contract.event(eventName);
    final decoded = ev.decodeResults(event.topics!, event.data!);
    final Map<String, dynamic> out = {};
    for (var i = 0; i < decoded.length; i++) {
      out['param_$i'] = decoded[i];
    }
    return out;
  }

  /// Fetch historical VoteCast events for a poll
  Future<List<Map<String, dynamic>>> fetchVoteHistory({required String abiJson, required String contractAddress, required int pollId}) async {
    final contract = loadContract(abiJson, contractAddress, 'Voting');
    final event = contract.event('VoteCast');
    final filter = FilterOptions.events(contract: contract, event: event, fromBlock: const BlockNum.genesis(), toBlock: const BlockNum.current());
    final logs = await _client!.getLogs(filter);
    List<Map<String, dynamic>> history = [];
    for (var log in logs) {
      final decoded = decodeEvent(abiJson: abiJson, contractAddress: contractAddress, eventName: 'VoteCast', event: log);
      if (decoded['pollId'] == pollId) {
        history.add(decoded);
      }
    }
    return history;
  }

  /// Get the contract owner address
  Future<String> getContractOwner(String abiJson, String contractAddress) async {
    final contract = loadContract(abiJson, contractAddress, 'Voting');
    final result = await callFunction(contract, 'owner', []);
    return result[0].toString();
  }

  /// Fetch tallies for a poll
  Future<Map<int, int>> fetchTallies({required String abiJson, required String contractAddress, required int pollId}) async {
    final contract = loadContract(abiJson, contractAddress, 'Voting');
    final result = await callFunction(contract, 'getTallies', [BigInt.from(pollId)]);
    final tallies = <int, int>{};
    for (var i = 0; i < result.length; i++) {
      tallies[i] = (result[i] as BigInt).toInt();
    }
    return tallies;
  }
}
