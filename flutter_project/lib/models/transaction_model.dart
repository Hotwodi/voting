class TransactionModel {
  final String txHash;
  final String description;
  final DateTime timestamp;
  final String status; // 'pending', 'confirmed', 'failed'

  TransactionModel({
    required this.txHash,
    required this.description,
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'txHash': txHash,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        txHash: json['txHash'],
        description: json['description'],
        timestamp: DateTime.parse(json['timestamp']),
        status: json['status'],
      );
}