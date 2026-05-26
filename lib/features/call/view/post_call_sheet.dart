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

  String get _ratingLabel => switch (_rating) {
        1 => 'Needs work',
        2 => 'Okay',
        3 => 'Good',
        4 => 'Great',
        _ => 'Amazing!',
      };

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.18),
                    primary.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Icon(Icons.celebration_rounded, color: primary, size: 26),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'How was the session?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Your rating helps Aarav improve every call.',
              style: TextStyle(color: AppColors.subtle, fontSize: 13),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: StarRating(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                _ratingLabel,
                key: ValueKey(_rating),
                style: TextStyle(
                  fontSize: 13,
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes for yourself (optional)',
              hintText: 'What worked, what to try next…',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Save & close',
            icon: Icons.check_rounded,
            loading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
