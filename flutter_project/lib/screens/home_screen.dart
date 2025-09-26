import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wallet_service.dart';
import '../services/web3_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import '../services/gasless_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _account = 'Not connected';
  String _abiJson = '';
  String _contractAddress = '';
  List<String> _options = [];
  Map<int, int> _tallies = {};
  StreamSubscription? _eventSub;
  List<TransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
    _loadPersistedTallies();
    _loadTransactions();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _saveTallies();
    super.dispose();
  }

  Future<void> _loadPersistedTallies() async {
    final prefs = await SharedPreferences.getInstance();
    final talliesJson = prefs.getString('tallies');
    if (talliesJson != null) {
      final Map<String, dynamic> talliesMap = jsonDecode(talliesJson);
      setState(() {
        _tallies = talliesMap.map((k, v) => MapEntry(int.parse(k), v as int));
      });
    }
  }

  Future<void> _saveTallies() async {
    final prefs = await SharedPreferences.getInstance();
    final talliesJson = jsonEncode(_tallies.map((k, v) => MapEntry(k.toString(), v)));
    await prefs.setString('tallies', talliesJson);
  }

  Future<void> _loadTransactions() async {
    final transactions = await TransactionService.instance.loadTransactions();
    setState(() {
      _transactions = transactions;
    });
  }

  Future<void> _loadSavedConfig() async {
    final cfg = await WalletService.instance.loadConfig();
    setState(() {
      _abiJson = cfg['abiJson'] ?? '';
      _contractAddress = cfg['contractAddress'] ?? '';
    });
  }

  Future<void> _connect() async {
    final wallet = WalletService.instance;
    await wallet.init();
    await wallet.connect();
    setState(() {
      _account = wallet.account ?? 'Unknown';
    });
  }

  Future<void> _loadOptions() async {
    if (_abiJson.isEmpty || _contractAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provide ABI and contract address')));
      return;
    }

    final contract = Web3Service.instance.loadContract(_abiJson, _contractAddress, 'Voting');
    final result = await Web3Service.instance.callFunction(contract, 'getOptions', [BigInt.from(0)]);
    // getOptions returns string[] so web3dart returns a List<dynamic> where the first item is the array
    final List options = result[0] as List;
    setState(() {
      _options = options.map((e) => e.toString()).toList();
      _tallies = { for (var i = 0; i < _options.length; i++) i: 0 };
    });

    // Subscribe to VoteCast events
    _eventSub?.cancel();
    _eventSub = Web3Service.instance
        .subscribeWithFallback(
          abiJson: _abiJson,
          contractAddress: _contractAddress,
          eventName: 'VoteCast',
          pollCallback: () async {
            final tallies = await Web3Service.instance.fetchTallies(abiJson: _abiJson, contractAddress: _contractAddress, pollId: 0);
            setState(() {
              _tallies = tallies;
            });
          },
        )
        .listen((event) {
      try {
        final decoded = Web3Service.instance.decodeEvent(abiJson: _abiJson, contractAddress: _contractAddress, eventName: 'VoteCast', event: event);
        final pollId = (decoded['param_0'] as BigInt).toInt();
        final optionId = (decoded['param_1'] as BigInt).toInt();
        final voter = decoded['param_2'].toString();
        if (pollId == 0) {
          setState(() {
            _tallies[optionId] = (_tallies[optionId] ?? 0) + 1;
          });
        }
        // Optionally show a small toast with voter address
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('VoteCast: option $optionId by $voter')));
      } catch (e) {
        // ignore parse errors
      }
    });
  }

  Future<void> _castVote(int optionId) async {
    if (_abiJson.isEmpty || _contractAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provide ABI and contract address')));
      return;
    }
    try {
      // check chain/network via a quick call
      final block = await Web3Service.instance.getLatestBlockNumber();
      if (block <= 0) throw Exception('Unable to connect to RPC');

      // estimate gas is not implemented in web3dart easily with WalletConnect; wallets will prompt
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening wallet to sign transaction...')));
      final txHash = await WalletService.instance.sendContractTransaction(
        abiJson: _abiJson,
        contractAddress: _contractAddress,
        functionName: 'vote',
        functionParams: [BigInt.from(optionId)],
      );
      if (txHash != null) {
        // Add to transaction queue
        final tx = TransactionModel(
          txHash: txHash,
          description: 'Vote for option $optionId',
          timestamp: DateTime.now(),
        );
        await TransactionService.instance.addTransaction(tx);
        _loadTransactions(); // refresh list
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tx submitted: $txHash')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending tx: $e')));
    }
  }

  Future<void> _gaslessVote(int optionId) async {
    try {
      final nonce = DateTime.now().millisecondsSinceEpoch; // Simple nonce
      final txHash = await GaslessService.instance.gaslessVote(0, optionId, nonce);
      if (txHash != null) {
        final tx = TransactionModel(
          txHash: txHash,
          description: 'Gasless vote for option $optionId',
          timestamp: DateTime.now(),
        );
        await TransactionService.instance.addTransaction(tx);
        _loadTransactions();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gasless vote submitted: $txHash')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gasless vote failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _saveConfig() async {
    await WalletService.instance.saveConfig(abiJson: _abiJson, contractAddress: _contractAddress);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Config saved')));
  }

  // Admin functions
  Future<void> _createPoll(String title, List<String> options) async {
    try {
      final txHash = await WalletService.instance.sendContractTransaction(
        abiJson: _abiJson,
        contractAddress: _contractAddress,
        functionName: 'createPoll',
        functionParams: [title, options],
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Poll creation tx: $txHash')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating poll: $e')));
    }
  }

  Future<void> _closePoll(int pollId) async {
    try {
      final txHash = await WalletService.instance.sendContractTransaction(
        abiJson: _abiJson,
        contractAddress: _contractAddress,
        functionName: 'closePoll',
        functionParams: [BigInt.from(pollId)],
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Poll closed tx: $txHash')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error closing poll: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polygon Voting App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account: $_account'),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Contract ABI JSON'),
              maxLines: 4,
              onChanged: (v) => _abiJson = v,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Contract address'),
              onChanged: (v) => _contractAddress = v,
            ),
            ElevatedButton(
              onPressed: _loadOptions,
              child: const Text('Load Poll Options'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _connect,
              child: const Text('Connect Wallet'),
            ),
            const SizedBox(height: 24),
            const Text('Demo Actions'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                // Example read-only call
                final web3 = Web3Service.instance;
                final block = await web3.getLatestBlockNumber();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Latest block: $block')));
              },
              child: const Text('Get Latest Block (Alchemy)'),
            ),
            const SizedBox(height: 24),
            const Text('Poll Options'),
            const SizedBox(height: 8),
            ..._options.asMap().entries.map((e) {
              final idx = e.key;
              final label = e.value;
              final tally = _tallies[idx] ?? 0;
              return ListTile(
                title: Text('$label'),
                subtitle: Text('Votes: $tally'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _castVote(idx),
                      child: const Text('Vote'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _gaslessVote(idx),
                      child: const Text('Gasless Vote'),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            const Divider(),
            const Text('Transaction Queue'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  return ListTile(
                    title: Text(tx.description),
                    subtitle: Text('${tx.status} - ${tx.timestamp}'),
                    trailing: Text(tx.txHash.substring(0, 10) + '...'),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text('Admin Panel'),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveConfig,
                  child: const Text('Save Config'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    // show dialog to create poll
                    final titleController = TextEditingController();
                    final optsController = TextEditingController();
                    final res = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Create Poll'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                            TextField(controller: optsController, decoration: const InputDecoration(labelText: 'Options (comma separated)')),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Create')),
                        ],
                      ),
                    );
                    if (res == true) {
                      final opts = optsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                      await _createPoll(titleController.text, opts);
                    }
                  },
                  child: const Text('Create Poll'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    // prompt for poll id to close
                    final idController = TextEditingController();
                    final res = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Close Poll'),
                        content: TextField(controller: idController, decoration: const InputDecoration(labelText: 'Poll ID')),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Close')),
                        ],
                      ),
                    );
                    if (res == true) {
                      final id = int.tryParse(idController.text) ?? 0;
                      await _closePoll(id);
                    }
                  },
                  child: const Text('Close Poll'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
