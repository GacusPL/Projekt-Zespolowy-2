import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/document.dart';
import '../bloc/documents_bloc.dart';

class DocumentsPage extends StatelessWidget {
  final String subjectId;
  const DocumentsPage({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DocumentsBloc>(
      create: (_) =>
          sl<DocumentsBloc>()..add(DocumentsLoadRequested(subjectId)),
      child: _DocumentsView(subjectId: subjectId),
    );
  }
}

class _DocumentsView extends StatelessWidget {
  final String subjectId;
  const _DocumentsView({required this.subjectId});

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'txt', 'md'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.bytes == null) return;

    final ext = (f.extension ?? '').toLowerCase();
    final type = switch (ext) {
      'pdf' => DocumentType.pdf,
      'png' || 'jpg' || 'jpeg' || 'webp' => DocumentType.image,
      _ => DocumentType.text,
    };

    if (!context.mounted) return;
    context.read<DocumentsBloc>().add(DocumentsUploadRequested(
          subjectId: subjectId,
          filename: f.name,
          type: type,
          bytes: f.bytes!,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentsBloc, DocumentsState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            _buildContent(context, state),
            if (state.uploading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _UploadProgress(
                  progress: state.uploadProgress,
                  stage: state.uploadStage ?? '',
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, DocumentsState state) {
    if (state.loading && state.documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.documents.isEmpty) {
      return EmptyState(
        icon: Icons.upload_file_outlined,
        title: 'Brak materiałów',
        description:
            'Wgraj PDF lub zdjęcie notatek — zostaną podzielone na fragmenty '
            'i zaindeksowane do wyszukiwania semantycznego.',
        action: FilledButton.icon(
          onPressed: state.uploading ? null : () => _pickFile(context),
          icon: const Icon(Icons.add),
          label: const Text('Wgraj plik'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: state.documents.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UploadCard(
              onPick: state.uploading ? null : () => _pickFile(context),
            ),
          );
        }
        final doc = state.documents[i - 1];
        return _DocumentTile(
          document: doc,
          onDelete: () => _confirmDelete(context, doc),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Document d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć dokument?'),
        content: Text('Usunąć "${d.filename}" i wszystkie jego fragmenty?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<DocumentsBloc>().add(DocumentsDeleteRequested(d.id));
    }
  }
}

class _UploadCard extends StatelessWidget {
  final VoidCallback? onPick;
  const _UploadCard({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.4),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cloud_upload_outlined,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wgraj nowy materiał',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PDF, zdjęcia notatek (PNG/JPG/WebP) lub pliki TXT/MD',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final Document document;
  final VoidCallback onDelete;
  const _DocumentTile({required this.document, required this.onDelete});

  IconData get _icon => switch (document.fileType) {
        DocumentType.pdf => Icons.picture_as_pdf_outlined,
        DocumentType.image => Icons.image_outlined,
        DocumentType.text => Icons.notes_outlined,
      };

  Color _color(BuildContext c) => switch (document.fileType) {
        DocumentType.pdf => Colors.red.shade400,
        DocumentType.image => Colors.purple.shade400,
        DocumentType.text => Colors.blue.shade400,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('d MMM yyyy, HH:mm', 'pl_PL');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _color(context).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_icon, color: _color(context)),
        ),
        title: Text(
          document.filename,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _color(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  document.fileType.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _color(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${document.chunkCount} fragmentów',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${dateFmt.format(document.uploadedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _UploadProgress extends StatelessWidget {
  final double progress;
  final String stage;
  const _UploadProgress({required this.progress, required this.stage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stage,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
