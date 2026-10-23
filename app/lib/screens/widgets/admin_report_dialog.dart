import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';

class AdminReportDialog extends ConsumerStatefulWidget {
  final String userInput;

  const AdminReportDialog({super.key, required this.userInput});

  static Future<bool?> show(BuildContext context, String userInput) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AdminReportDialog(userInput: userInput),
    );
  }

  @override
  ConsumerState<AdminReportDialog> createState() => _AdminReportDialogState();
}

class _AdminReportDialogState extends ConsumerState<AdminReportDialog> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);

      await api.submitAdminReport(
        userInput: widget.userInput,
        userNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        userEmail: auth.email,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.report_problem_outlined,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.reportToAdminTitle ?? 'Submit Report to Admin',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n?.reportToAdminDesc ??
                  'This request is not currently supported. You can send a report to the admin for manual review.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),

            // Input display
            Text(
              l10n?.reportInputLabel ?? 'Request content:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                widget.userInput,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 12),

            // Notes input
            Text(
              l10n?.reportNotesLabel ?? 'Additional notes (optional):',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n?.reportNotesHint ??
                    'Describe what you need or why you requested this...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitReport,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send, size: 16),
          label: Text(
            _isSubmitting
                ? (l10n?.reportSubmitting ?? 'Submitting...')
                : (l10n?.reportSubmit ?? 'Submit Report'),
          ),
        ),
      ],
    );
  }
}
