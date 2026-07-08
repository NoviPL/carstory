class Car {
  final int? id;
  final String name;
  final String brand;
  final String model;
  final int year;
  final int mileage;
  final String vin;
  final String plateNumber;
  final String createdAt;

  const Car({
    this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.year,
    required this.mileage,
    required this.vin,
    required this.plateNumber,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'year': year,
      'mileage': mileage,
      'vin': vin,
      'plateNumber': plateNumber,
      'createdAt': createdAt,
    };
  }

  factory Car.fromMap(Map<String, Object?> map) {
    return Car(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      mileage: map['mileage'] as int,
      vin: map['vin'] as String,
      plateNumber: map['plateNumber'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}