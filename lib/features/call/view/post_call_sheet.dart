import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class MemberPostCallSheet extends ConsumerStatefulWidget {
  const MemberPostCallSheet({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<MemberPostCallSheet> createState() => _MemberPostCallSheetState();
}

class _MemberPostCallSheetState extends ConsumerState<MemberPostCallSheet> {
  int _rating = 5;
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    await ref.read(logServiceProvider).patchSession(
          widget.sessionId,
          rating: _rating,
          memberNotes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session saved to your logs.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How was the session?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: StarRating(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes for yourself (optional)',
              hintText: 'What worked, what to try next…',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'Save & close', loading: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
