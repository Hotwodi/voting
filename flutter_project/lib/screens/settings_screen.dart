import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/wallet_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _abiJson = '';
  String _contractAddress = '';
  bool _gaslessEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cfg = await WalletService.instance.loadConfig();
    setState(() {
      _abiJson = cfg['abiJson'] ?? '';
      _contractAddress = cfg['contractAddress'] ?? '';
    });
  }

  Future<void> _saveSettings() async {
    await WalletService.instance.saveConfig(abiJson: _abiJson, contractAddress: _contractAddress);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
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
                child: ListView(
                  children: [
                    const Text(
                      'Contract Configuration',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Contract ABI JSON',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      onChanged: (v) => _abiJson = v,
                      controller: TextEditingController(text: _abiJson),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Contract Address',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (v) => _contractAddress = v,
                      controller: TextEditingController(text: _contractAddress),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Wallet Settings',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Gasless Voting', style: TextStyle(color: Colors.white)),
                      value: _gaslessEnabled,
                      onChanged: (v) => setState(() => _gaslessEnabled = v),
                      activeColor: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'App Settings',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Theme', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Light/Dark (coming soon)', style: TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        // TODO: Theme switcher
                      },
                    ),
                    ListTile(
                      title: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.clear, color: Colors.white),
                      onTap: () {
                        // TODO: Clear shared prefs
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}