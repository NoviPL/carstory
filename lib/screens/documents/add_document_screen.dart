import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../models/car.dart';
import '../../models/vehicle_document.dart';
import '../../repositories/vehicle_document_repository.dart';
import '../../services/document_storage_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';

class AddDocumentScreen extends StatefulWidget {
  final Car car;
  final VehicleDocument? document;

  const AddDocumentScreen({super.key, required this.car, this.document});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  static const List<String> _categories = [
    'Dowód rejestracyjny',
    'Polisa OC',
    'Polisa AC',
    'Badanie techniczne',
    'Faktura',
    'Paragon',
    'Umowa',
    'Instrukcja',
    'Inne',
  ];

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _noteController = TextEditingController();

  final _repository = VehicleDocumentRepository();

  final _storageService = DocumentStorageService();

  String _selectedCategory = _categories.first;

  String? _selectedFilePath;
  String? _selectedFileName;
  String? _selectedFileType;

  bool _hasExpiryDate = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final document = widget.document;

    if (document != null) {
      _titleController.text = document.title;
      _noteController.text = document.note;
      _expiryDateController.text = document.expiryDate ?? '';

      _selectedCategory = _categories.contains(document.category)
          ? document.category
          : 'Inne';

      _selectedFilePath = document.filePath;
      _selectedFileName = document.fileName;
      _selectedFileType = document.fileType;
      _hasExpiryDate = document.expiryDate != null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _expiryDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'To pole jest wymagane';
    }

    return null;
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();

    final initialDate = DateTime.tryParse(_expiryDateController.text) ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
    );

    if (pickedDate == null) return;

    _expiryDateController.text = _formatDate(pickedDate);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final selectedFile = result.files.single;
    final selectedPath = selectedFile.path;

    if (selectedPath == null) {
      return;
    }

    setState(() {
      _selectedFilePath = selectedPath;
      _selectedFileName = selectedFile.name;

      _selectedFileType = path
          .extension(selectedFile.name)
          .replaceFirst('.', '')
          .toLowerCase();

      if (_titleController.text.trim().isEmpty) {
        _titleController.text = path.basenameWithoutExtension(
          selectedFile.name,
        );
      }
    });
  }

  bool get _selectedFileIsImage {
    final type = _selectedFileType?.toLowerCase();

    return type == 'jpg' || type == 'jpeg' || type == 'png' || type == 'webp';
  }

  Widget _filePreview() {
    final selectedPath = _selectedFilePath;

    if (selectedPath == null) {
      return AppCard(
        onTap: _pickFile,
        child: const Column(
          children: [
            Icon(Icons.upload_file_outlined, size: 46),
            SizedBox(height: 12),
            Text('Wybierz zdjęcie lub plik PDF', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return AppCard(
      onTap: _pickFile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedFileIsImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(
                  File(selectedPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image_outlined, size: 48),
                    );
                  },
                ),
              ),
            )
          else
            const Center(child: Icon(Icons.picture_as_pdf_outlined, size: 64)),
          const SizedBox(height: 14),
          Text(
            _selectedFileName ?? 'Dokument',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          const Text('Dotknij, aby wybrać inny plik'),
        ],
      ),
    );
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final carId = widget.car.id;

    if (carId == null) return;

    final sourceFilePath = _selectedFilePath;
    final sourceFileName = _selectedFileName;
    final sourceFileType = _selectedFileType;

    if (sourceFilePath == null ||
        sourceFileName == null ||
        sourceFileType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wybierz plik dokumentu.')));

      return;
    }

    if (_hasExpiryDate && _expiryDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz datę ważności dokumentu.')),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    final existingDocument = widget.document;

    String storedFilePath = sourceFilePath;

    final selectedDifferentFile =
        existingDocument == null || sourceFilePath != existingDocument.filePath;

    if (selectedDifferentFile) {
      storedFilePath = await _storageService.saveDocument(
        carId: carId,
        sourcePath: sourceFilePath,
        originalFileName: sourceFileName,
      );
    }

    final document = VehicleDocument(
      id: existingDocument?.id,
      carId: carId,
      title: _titleController.text.trim(),
      category: _selectedCategory,
      filePath: storedFilePath,
      fileName: sourceFileName,
      fileType: sourceFileType,
      expiryDate: _hasExpiryDate ? _expiryDateController.text.trim() : null,
      note: _noteController.text.trim(),
      createdAt:
          existingDocument?.createdAt ?? DateTime.now().toIso8601String(),
    );

    if (existingDocument == null) {
      await _repository.insertDocument(document);
    } else {
      await _repository.updateDocument(document);

      if (selectedDifferentFile) {
        await _storageService.deleteDocument(existingDocument.filePath);
      }
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.document == null ? 'Nowy dokument' : 'Edytuj dokument',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _filePreview(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Nazwa dokumentu',
                hintText: 'Np. polisa OC 2026',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategoria'),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dokument ma termin ważności'),
              value: _hasExpiryDate,
              onChanged: (value) {
                setState(() {
                  _hasExpiryDate = value;

                  if (!value) {
                    _expiryDateController.clear();
                  }
                });
              },
            ),
            if (_hasExpiryDate) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _expiryDateController,
                readOnly: true,
                onTap: _pickExpiryDate,
                decoration: const InputDecoration(
                  labelText: 'Ważny do',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notatka',
                hintText: 'Opcjonalne dodatkowe informacje',
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _isSaving
                  ? 'Zapisywanie...'
                  : widget.document == null
                  ? 'Zapisz dokument'
                  : 'Zapisz zmiany',
              icon: Icons.save,
              onPressed: _isSaving ? null : _saveDocument,
            ),
          ],
        ),
      ),
    );
  }
}
