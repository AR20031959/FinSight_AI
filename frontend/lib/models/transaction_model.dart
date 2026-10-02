class TransactionModel {
  final int id;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String date;
  final String? merchant;
  final String? note;
  final bool isRecurring;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.merchant,
    this.note,
    this.isRecurring = false,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      type: json['type'] ?? 'expense',
      category: json['category'] ?? 'Other',
      date: json['date'] ?? '',
      merchant: json['merchant'],
      note: json['note'],
      isRecurring: json['is_recurring'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
      'merchant': merchant,
      'note': note,
      'is_recurring': isRecurring,
    };
  }
}
