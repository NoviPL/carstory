class CarPhoto {
  final int? id;
  final int carId;
  final String filePath;
  final String caption;
  final bool isCover;
  final String createdAt;

  const CarPhoto({
    this.id,
    required this.carId,
    required this.filePath,
    required this.caption,
    required this.isCover,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'carId': carId,
      'filePath': filePath,
      'caption': caption,
      'isCover': isCover ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory CarPhoto.fromMap(Map<String, Object?> map) {
    return CarPhoto(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      filePath: map['filePath'] as String,
      caption: map['caption'] as String,
      isCover: (map['isCover'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] as String,
    );
  }

  CarPhoto copyWith({
    int? id,
    int? carId,
    String? filePath,
    String? caption,
    bool? isCover,
    String? createdAt,
  }) {
    return CarPhoto(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      filePath: filePath ?? this.filePath,
      caption: caption ?? this.caption,
      isCover: isCover ?? this.isCover,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
