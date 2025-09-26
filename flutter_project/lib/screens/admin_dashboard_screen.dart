import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/wallet_service.dart';
import '../services/web3_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isAdmin = false;
  List<Map<String, dynamic>> _polls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadPolls();
  }

  Future<void> _checkAdminAndLoadPolls() async {
    setState(() => _loading = true);
    try {
      final cfg = await WalletService.instance.loadConfig();
      final abi = cfg['abiJson'] ?? '';
      final address = cfg['contractAddress'] ?? '';
      if (abi.isEmpty || address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contract config not set')),
        );
        return;
      }

      final account = WalletService.instance.account;
      if (account == null || account.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet not connected')),
        );
        return;
      }

      // Check if user is admin
      final owner = await Web3Service.instance.getContractOwner(abi, address);
      _isAdmin = owner.toLowerCase() == account.toLowerCase();

      if (_isAdmin) {
        // For demo, load some sample polls. In real app, fetch from contract or API
        _polls = [
          {'id': 1, 'title': 'Sample Poll 1', 'open': true},
          {'id': 2, 'title': 'Sample Poll 2', 'open': false},
        ];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createPoll() async {
    // Simple dialog for poll creation
    final titleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Poll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Poll Title'),
            ),
            // Add options input here if needed
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              // Call contract createPoll
              // For now, just add to list
              setState(() {
                _polls.add({
                  'id': _polls.length + 1,
                  'title': titleController.text,
                  'open': true,
                });
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
            : !_isAdmin
                ? const Center(
                    child: Text(
                      'Access Denied: Not Admin',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Glass effect container
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
                                child: ListView.builder(
                                  itemCount: _polls.length,
                                  itemBuilder: (ctx, i) {
                                    final poll = _polls[i];
                                    return ListTile(
                                      title: Text(
                                        poll['title'],
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        'ID: ${poll['id']} - ${poll['open'] ? 'Open' : 'Closed'}',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          poll['open'] ? Icons.close : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          // Toggle open/close
                                          setState(() {
                                            poll['open'] = !poll['open'];
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _createPoll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Create New Poll'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/create-poll'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Advanced Poll Creation'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}