class FuelEntry {
  final int? id;
  final int carId;
  final int mileage;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final String date;
  final String createdAt;
  final bool isFullTank;

  const FuelEntry({
    this.id,
    required this.carId,
    required this.mileage,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    required this.date,
    required this.createdAt,
    required this.isFullTank,
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
      'isFullTank': isFullTank ? 1 : 0,
    };
  }

  factory FuelEntry.fromMap(Map<String, Object?> map) {
    return FuelEntry(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      mileage: map['mileage'] as int,
      liters: (map['liters'] as num).toDouble(),
      pricePerLiter: (map['pricePerLiter'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),
      date: map['date'] as String,
      createdAt: map['createdAt'] as String,
      isFullTank: (map['isFullTank'] as int? ?? 1) == 1,
    );
  }
}