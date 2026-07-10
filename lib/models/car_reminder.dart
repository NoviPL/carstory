class CarReminder {
  final int? id;
  final int carId;
  final String title;
  final String type;
  final String? dueDate;
  final int? dueMileage;
  final String note;
  final bool isCompleted;
  final String createdAt;

  const CarReminder({
    this.id,
    required this.carId,
    required this.title,
    required this.type,
    required this.dueDate,
    required this.dueMileage,
    required this.note,
    required this.isCompleted,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'carId': carId,
      'title': title,
      'type': type,
      'dueDate': dueDate,
      'dueMileage': dueMileage,
      'note': note,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory CarReminder.fromMap(Map<String, Object?> map) {
    return CarReminder(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      title: map['title'] as String,
      type: map['type'] as String,
      dueDate: map['dueDate'] as String?,
      dueMileage: map['dueMileage'] as int?,
      note: map['note'] as String,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] as String,
    );
  }
}