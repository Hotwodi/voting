import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../services/web3_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _account = 'Not connected';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _connect() async {
    final wallet = WalletService.instance;
    await wallet.init();
    await wallet.connect();
    setState(() {
      _account = wallet.account ?? 'Unknown';
    });
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
          ],
        ),
      ),
    );
  }
}
