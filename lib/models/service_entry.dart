class ServiceEntry {
  final int? id;
  final int carId;
  final String title;
  final String description;
  final int mileage;
  final double cost;
  final String date;
  final String createdAt;

  const ServiceEntry({
    this.id,
    required this.carId,
    required this.title,
    required this.description,
    required this.mileage,
    required this.cost,
    required this.date,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'carId': carId,
      'title': title,
      'description': description,
      'mileage': mileage,
      'cost': cost,
      'date': date,
      'createdAt': createdAt,
    };
  }

  factory ServiceEntry.fromMap(Map<String, Object?> map) {
    return ServiceEntry(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      mileage: map['mileage'] as int,
      cost: map['cost'] as double,
      date: map['date'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}
