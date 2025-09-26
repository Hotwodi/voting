import 'dart:async';
import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../services/web3_service.dart';

class PollDetailScreen extends StatefulWidget {
  final int pollId;

  const PollDetailScreen({super.key, required this.pollId});

  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen> {
  List<String> _options = [];
  Map<int, int> _tallies = {};
  List<Map<String, dynamic>> _history = [];
  bool _voted = false;
  bool _open = true;
  StreamSubscription? _eventSub;
  String _abiJson = '';
  String _contractAddress = '';

  @override
  void initState() {
    super.initState();
    _loadConfigAndData();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _loadConfigAndData() async {
    final cfg = await WalletService.instance.loadConfig();
    _abiJson = cfg['abiJson'] ?? '';
    _contractAddress = cfg['contractAddress'] ?? '';
    if (_abiJson.isEmpty || _contractAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ABI and contract address not set')));
      return;
    }

    await _loadPollData();
    _subscribeToEvents();
  }

  Future<void> _loadPollData() async {
    final contract = Web3Service.instance.loadContract(_abiJson, _contractAddress, 'Voting');
    final optionsRes = await Web3Service.instance.callFunction(contract, 'getOptions', [BigInt.from(widget.pollId)]);
    final List opts = optionsRes[0] as List;
    _options = opts.map((e) => e.toString()).toList();

    final tallies = await Web3Service.instance.fetchTallies(abiJson: _abiJson, contractAddress: _contractAddress, pollId: widget.pollId);
    final history = await Web3Service.instance.fetchVoteHistory(abiJson: _abiJson, contractAddress: _contractAddress, pollId: widget.pollId);
    setState(() {
      _tallies = tallies;
      _history = history;
    });
  }

  void _subscribeToEvents() {
    _eventSub = Web3Service.instance.subscribeWithFallback(
      abiJson: _abiJson,
      contractAddress: _contractAddress,
      eventName: 'VoteCast',
      pollCallback: () async => await _loadPollData(),
    ).listen((event) {
      try {
        final decoded = Web3Service.instance.decodeEvent(abiJson: _abiJson, contractAddress: _contractAddress, eventName: 'VoteCast', event: event);
        final pollId = (decoded['param_0'] as BigInt).toInt();
        if (pollId == widget.pollId) {
          final optionId = (decoded['param_1'] as BigInt).toInt();
          setState(() {
            _tallies[optionId] = (_tallies[optionId] ?? 0) + 1;
          });
        }
      } catch (e) {
        // ignore
      }
    });
  }

  Future<void> _castVote(int optionId) async {
    try {
      final txHash = await WalletService.instance.sendContractTransaction(
        abiJson: _abiJson,
        contractAddress: _contractAddress,
        functionName: 'vote',
        functionParams: [BigInt.from(optionId)],
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vote submitted: $txHash')));
      setState(() {
        _voted = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error voting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poll Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_open ? 'Poll is OPEN' : 'Poll is CLOSED'),
            const SizedBox(height: 16),
            const Text('Options:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _options.length,
              itemBuilder: (context, index) {
                final label = _options[index];
                final tally = _tallies[index] ?? 0;
                return ListTile(
                  title: Text(label),
                  subtitle: Text('Votes: $tally'),
                  trailing: _voted || !_open
                      ? null
                      : ElevatedButton(
                          onPressed: () => _castVote(index),
                          child: const Text('Vote'),
                        ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Vote History:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final vote = _history[index];
                final voter = vote['voter'] ?? 'Unknown';
                final optionId = (vote['optionId'] as int?) ?? 0;
                final option = optionId < _options.length ? _options[optionId] : 'Unknown';
                return ListTile(
                  title: Text('Voter: ${voter.toString().length > 10 ? voter.toString().substring(0, 10) : voter}...'),
                  subtitle: Text('Voted for: $option'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}