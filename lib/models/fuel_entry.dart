class FuelEntry {
  final int? id;
  final int carId;
  final int mileage;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final String date;
  final String createdAt;

  const FuelEntry({
    this.id,
    required this.carId,
    required this.mileage,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    required this.date,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'carId': carId,
      'mileage': mileage,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'totalCost': totalCost,
      'date': date,
      'createdAt': createdAt,
    };
  }

  factory FuelEntry.fromMap(Map<String, Object?> map) {
    return FuelEntry(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      mileage: map['mileage'] as int,
      liters: map['liters'] as double,
      pricePerLiter: map['pricePerLiter'] as double,
      totalCost: map['totalCost'] as double,
      date: map['date'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}