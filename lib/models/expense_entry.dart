class ExpenseEntry {
  final int? id;
  final int carId;
  final String title;
  final String category;
  final double amount;
  final String date;
  final String note;
  final String createdAt;

  const ExpenseEntry({
    this.id,
    required this.carId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'carId': carId,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date,
      'note': note,
      'createdAt': createdAt,
    };
  }

  factory ExpenseEntry.fromMap(Map<String, Object?> map) {
    return ExpenseEntry(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      note: map['note'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}