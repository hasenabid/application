import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/user.dart';
import '../data/auth_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return AuthController(authRepository);
    });

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;
  Timer? _pollingTimer; // Tracks the 2-second background network interval loop

  AuthController(this._authRepository) : super(const AsyncData(null));

  /// 🔐 Classic Form-Based Email Login (Kept for fallback administration access)
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _authRepository.login(email, password);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 🕒 1. FIXED: Starts checking the Spring Boot server every 2 seconds for an RFID scan
  void startRfidPollingLoop() {
    _pollingTimer?.cancel(); // Safety reset: clear out any preexisting timers

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // Pause network polling requests if the application state is currently logging in
      if (state is AsyncLoading || state.valueOrNull != null) return;

      try {
        final authenticatedUser = await _authRepository.checkPendingRfidScan();

        if (authenticatedUser != null) {
          timer
              .cancel(); // Stop network activities instantly once badge data maps successfully
          state = AsyncData(
            authenticatedUser,
          ); // Unlocks the target user screen across the system globally!
        }
      } catch (e) {
        // Fail silently during background ticks to keep the operator terminal logs pristine
        debugPrint('RFID Background Polling Trace: $e');
      }
    });
  }

  /// 🕒 2. FIXED: Stops background network cycles when moving out of the Login Screen
  void stopRfidPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Clears the user session profile instance configurations cleanly
  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _authRepository.logout();
      state = const AsyncData(null);
      startRfidPollingLoop(); // Automatically re-triggers card listener polling upon operator logouts
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
