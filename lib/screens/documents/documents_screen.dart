import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/theme.dart';
import '../../models/car.dart';
import '../../models/vehicle_document.dart';
import '../../repositories/vehicle_document_repository.dart';
import '../../services/document_storage_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_section_title.dart';
import '../../widgets/app_snackbar.dart';
import 'add_document_screen.dart';

class DocumentsScreen extends StatefulWidget {
  final Car car;

  const DocumentsScreen({super.key, required this.car});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _repository = VehicleDocumentRepository();

  final _storageService = DocumentStorageService();

  List<VehicleDocument> _documents = [];
  bool _isLoading = true;

  int get _expiringCount {
    return _documents.where((document) {
      final expiryDateText = document.expiryDate;

      if (expiryDateText == null) {
        return false;
      }

      final expiryDate = DateTime.tryParse(expiryDateText);

      if (expiryDate == null) {
        return false;
      }

      final today = DateTime.now();

      final currentDay = DateTime(today.year, today.month, today.day);

      final difference = expiryDate.difference(currentDay).inDays;

      return difference >= 0 && difference <= 30;
    }).length;
  }

  int get _expiredCount {
    return _documents.where((document) {
      final expiryDateText = document.expiryDate;

      if (expiryDateText == null) {
        return false;
      }

      final expiryDate = DateTime.tryParse(expiryDateText);

      if (expiryDate == null) {
        return false;
      }

      final today = DateTime.now();

      final currentDay = DateTime(today.year, today.month, today.day);

      return expiryDate.isBefore(currentDay);
    }).length;
  }

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final carId = widget.car.id;

    if (carId == null) return;

    final documents = await _repository.getDocumentsForCar(carId);

    if (!mounted) return;

    setState(() {
      _documents = documents;
      _isLoading = false;
    });
  }

  Future<void> _openForm({VehicleDocument? document}) async {
    final currentContext = context;

    final result = await Navigator.push<bool>(
      currentContext,
      MaterialPageRoute(
        builder: (_) => AddDocumentScreen(car: widget.car, document: document),
      ),
    );

    if (result != true) return;

    await _loadDocuments();

    if (!currentContext.mounted) return;

    showAppSnackBar(
      context: currentContext,
      message: document == null
          ? 'Dokument został dodany.'
          : 'Dokument został zaktualizowany.',
    );
  }

  Future<void> _openDocument(VehicleDocument document) async {
    final file = File(document.filePath);

    if (!await file.exists()) {
      if (!mounted) return;

      showAppSnackBar(
        context: context,
        message: 'Plik dokumentu nie istnieje.',
      );

      return;
    }

    final result = await OpenFilex.open(document.filePath);

    if (result.type == ResultType.done) {
      return;
    }

    if (!mounted) return;

    showAppSnackBar(
      context: context,
      message: 'Nie udało się otworzyć dokumentu.',
    );
  }

  Future<void> _deleteDocument(VehicleDocument document) async {
    final id = document.id;

    if (id == null) return;

    final currentContext = context;

    final confirmed = await showAppConfirmDialog(
      context: currentContext,
      title: 'Usunąć dokument?',
      message: 'Dokument i zapisany plik zostaną trwale usunięte.',
    );

    if (!confirmed) return;

    await _repository.deleteDocument(id);

    await _storageService.deleteDocument(document.filePath);

    await _loadDocuments();

    if (!currentContext.mounted) return;

    showAppSnackBar(
      context: currentContext,
      message: 'Dokument został usunięty.',
    );
  }

  _DocumentStatus _statusFor(VehicleDocument document) {
    final expiryDateText = document.expiryDate;

    if (expiryDateText == null) {
      return const _DocumentStatus(
        label: 'Bez terminu',
        level: _DocumentLevel.normal,
      );
    }

    final expiryDate = DateTime.tryParse(expiryDateText);

    if (expiryDate == null) {
      return const _DocumentStatus(
        label: 'Nieznany termin',
        level: _DocumentLevel.normal,
      );
    }

    final today = DateTime.now();

    final currentDay = DateTime(today.year, today.month, today.day);

    final difference = expiryDate.difference(currentDay).inDays;

    if (difference < 0) {
      return const _DocumentStatus(
        label: 'Po terminie',
        level: _DocumentLevel.expired,
      );
    }

    if (difference == 0) {
      return const _DocumentStatus(
        label: 'Wygasa dzisiaj',
        level: _DocumentLevel.warning,
      );
    }

    if (difference <= 30) {
      return _DocumentStatus(
        label: 'Wygasa za $difference dni',
        level: _DocumentLevel.warning,
      );
    }

    return _DocumentStatus(
      label: 'Ważny do $expiryDateText',
      level: _DocumentLevel.valid,
    );
  }

  Color _statusColor(_DocumentLevel level) {
    switch (level) {
      case _DocumentLevel.expired:
        return AppColors.danger;
      case _DocumentLevel.warning:
        return AppColors.warning;
      case _DocumentLevel.valid:
        return AppColors.success;
      case _DocumentLevel.normal:
        return AppColors.muted;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Dowód rejestracyjny':
        return Icons.badge_outlined;
      case 'Polisa OC':
      case 'Polisa AC':
        return Icons.verified_user_outlined;
      case 'Badanie techniczne':
        return Icons.fact_check_outlined;
      case 'Faktura':
      case 'Paragon':
        return Icons.receipt_long_outlined;
      case 'Umowa':
        return Icons.handshake_outlined;
      case 'Instrukcja':
        return Icons.menu_book_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Widget _summaryItem({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentThumbnail(VehicleDocument document) {
    if (document.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(document.filePath),
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _documentIcon(document);
          },
        ),
      );
    }

    return _documentIcon(document);
  }

  Widget _documentIcon(VehicleDocument document) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        document.isPdf
            ? Icons.picture_as_pdf_outlined
            : _categoryIcon(document.category),
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dokumenty',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Dokument'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSectionTitle(
              title: widget.car.name,
              subtitle: 'Polisy, faktury, dowód i ważne pliki.',
            ),
            const SizedBox(height: 20),
            if (!_isLoading && _documents.isNotEmpty) ...[
              AppCard(
                child: Row(
                  children: [
                    _summaryItem(
                      context: context,
                      icon: Icons.folder_copy_outlined,
                      value: _documents.length.toString(),
                      label: 'Dokumenty',
                    ),
                    const SizedBox(width: 16),
                    _summaryItem(
                      context: context,
                      icon: Icons.warning_amber_outlined,
                      value: _expiringCount.toString(),
                      label: 'Wygasają',
                    ),
                    const SizedBox(width: 16),
                    _summaryItem(
                      context: context,
                      icon: Icons.error_outline,
                      value: _expiredCount.toString(),
                      label: 'Po terminie',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_documents.isEmpty)
              const AppEmptyState(
                icon: Icons.folder_open_outlined,
                title: 'Brak dokumentów',
                message:
                    'Dodaj polisę, fakturę, dowód rejestracyjny lub inny plik.',
              )
            else
              ..._documents.map((document) {
                final status = _statusFor(document);

                final statusColor = _statusColor(status.level);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => _openDocument(document),
                    child: Row(
                      children: [
                        _documentThumbnail(document),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                document.category,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                status.label,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              if (document.note.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  document.note,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'open':
                                _openDocument(document);
                                break;
                              case 'edit':
                                _openForm(document: document);
                                break;
                              case 'delete':
                                _deleteDocument(document);
                                break;
                            }
                          },
                          itemBuilder: (context) {
                            return const [
                              PopupMenuItem(
                                value: 'open',
                                child: Text('Otwórz'),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edytuj'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Usuń'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

enum _DocumentLevel { expired, warning, valid, normal }

class _DocumentStatus {
  final String label;
  final _DocumentLevel level;

  const _DocumentStatus({required this.label, required this.level});
}
