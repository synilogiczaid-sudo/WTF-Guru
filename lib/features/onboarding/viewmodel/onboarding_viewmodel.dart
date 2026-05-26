import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class OnboardingViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<User> register({
    required String name,
    required String email,
    required String trainerId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ValidationError('Name is required.');
    }
    Validators.ensureEmail(email);

    final auth = ref.read(authServiceProvider);
    final user = await auth.registerMember(
      name: trimmedName,
      email: email,
      assignedTrainerId: trainerId,
    );
    await auth.markOnboarded();
    ref.invalidate(currentUserProvider);
    return user;
  }
}

final onboardingViewModelProvider =
    AsyncNotifierProvider<OnboardingViewModel, void>(OnboardingViewModel.new);
