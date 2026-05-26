import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../viewmodel/onboarding_viewmodel.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController(text: 'DK');
  final _email = TextEditingController(text: 'dk@wtf.fit');
  String _trainerId = 'trainer_aarav';
  bool _busy = false;

  static const _trainerOptions = [
    ('trainer_aarav', 'Aarav (Lead Trainer)'),
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(onboardingViewModelProvider.notifier)
          .register(name: _name.text, email: _email.text, trainerId: _trainerId);
      if (mounted) context.go('/home');
    } on ValidationError catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, message: e.message);
    } catch (e, st) {
      if (!mounted) return;
      showErrorSnackbar(
        context,
        message: 'Something went wrong. Please try again.',
        error: e,
        stackTrace: st,
        tag: LogTag.auth,
        logMessage: 'register failed',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Let's get to know you")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Your name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Pick your trainer',
                style: TextStyle(fontSize: 14, color: AppColors.subtle),
              ),
              const SizedBox(height: AppSpacing.sm),
              ..._trainerOptions.map(
                (t) => InkWell(
                  onTap: () => setState(() => _trainerId = t.$1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          _trainerId == t.$1
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: _trainerId == t.$1
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.subtle,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(t.$2,
                            style: const TextStyle(fontSize: 15, color: AppColors.ink)),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(label: 'Continue', loading: _busy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
