import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/wallet_service.dart';

class PollCreationScreen extends StatefulWidget {
  const PollCreationScreen({super.key});

  @override
  State<PollCreationScreen> createState() => _PollCreationScreenState();
}

class _PollCreationScreenState extends State<PollCreationScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [TextEditingController()];
  bool _loading = false;

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 1) {
      setState(() {
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _createPoll() async {
    if (_titleController.text.isEmpty || _optionControllers.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

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

      final options = _optionControllers.map((c) => c.text.trim()).toList();
      final txHash = await WalletService.instance.sendContractTransaction(
        abiJson: abi,
        contractAddress: address,
        functionName: 'createPoll',
        functionParams: [_titleController.text, options],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Poll created: $txHash')),
      );
      Navigator.of(context).pop(); // Go back
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Poll'),
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
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            TextField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Poll Title',
                                labelStyle: TextStyle(color: Colors.white),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description (optional)',
                                labelStyle: TextStyle(color: Colors.white),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Options',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            ..._optionControllers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final controller = entry.value;
                              return Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                        labelText: 'Option ${index + 1}',
                                        labelStyle: const TextStyle(color: Colors.white),
                                        enabledBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white70),
                                        ),
                                      ),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: Colors.white),
                                    onPressed: () => _removeOption(index),
                                  ),
                                ],
                              );
                            }),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _addOption,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                              child: const Text('Add Option'),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _createPoll,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              ),
                              child: const Text('Create Poll'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}