class VehicleDocument {
  final int? id;
  final int carId;
  final String title;
  final String category;
  final String filePath;
  final String fileName;
  final String fileType;
  final String? expiryDate;
  final String note;
  final String createdAt;

  const VehicleDocument({
    this.id,
    required this.carId,
    required this.title,
    required this.category,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.expiryDate,
    required this.note,
    required this.createdAt,
  });

  bool get isImage {
    final type = fileType.toLowerCase();

    return type == 'jpg' || type == 'jpeg' || type == 'png' || type == 'webp';
  }

  bool get isPdf => fileType.toLowerCase() == 'pdf';

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'carId': carId,
      'title': title,
      'category': category,
      'filePath': filePath,
      'fileName': fileName,
      'fileType': fileType,
      'expiryDate': expiryDate,
      'note': note,
      'createdAt': createdAt,
    };
  }

  factory VehicleDocument.fromMap(Map<String, Object?> map) {
    return VehicleDocument(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      title: map['title'] as String,
      category: map['category'] as String,
      filePath: map['filePath'] as String,
      fileName: map['fileName'] as String,
      fileType: map['fileType'] as String,
      expiryDate: map['expiryDate'] as String?,
      note: map['note'] as String,
      createdAt: map['createdAt'] as String,
    );
  }

  VehicleDocument copyWith({
    int? id,
    int? carId,
    String? title,
    String? category,
    String? filePath,
    String? fileName,
    String? fileType,
    String? expiryDate,
    String? note,
    String? createdAt,
  }) {
    return VehicleDocument(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      title: title ?? this.title,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      expiryDate: expiryDate ?? this.expiryDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
