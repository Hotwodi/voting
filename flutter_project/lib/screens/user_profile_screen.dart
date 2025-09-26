import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/wallet_service.dart';
import '../services/web3_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _account = 'Not connected';
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final account = WalletService.instance.account;
      if (account != null && account.isNotEmpty) {
        _account = account;
        // Load voting history - for demo, fetch from all polls
        final cfg = await WalletService.instance.loadConfig();
        final abi = cfg['abiJson'] ?? '';
        final address = cfg['contractAddress'] ?? '';
        if (abi.isNotEmpty && address.isNotEmpty) {
          // Fetch history for poll 1 as example
          _history = await Web3Service.instance.fetchVoteHistory(abiJson: abi, contractAddress: address, pollId: 1);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Glass effect for profile info
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.account_circle, size: 50, color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Wallet Address',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _account,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Total Votes: ${_history.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Glass effect for history
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: _history.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No voting history yet',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _history.length,
                                    itemBuilder: (ctx, i) {
                                      final vote = _history[i];
                                      return ListTile(
                                        title: Text(
                                          'Voted for option ${vote['optionId']}',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        subtitle: Text(
                                          'Poll ID: ${vote['pollId']}',
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}