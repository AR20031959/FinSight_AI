import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/local_storage_service.dart';

class AuthState {
  final bool isAuthenticated;
  final String? email;
  final String? fullName;
  final String role;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = true,
    this.email = "demo@finsight.ai",
    this.fullName = "Alex Morgan",
    this.role = "user",
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    String? fullName,
    String? role,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    final token = await LocalStorageService.loadAuthToken();
    if (token != null) {
      ApiClient.setAuthToken(token);
    }
    final profile = await LocalStorageService.loadUserProfile();
    if (profile['email'] != null || profile['fullName'] != null) {
      state = state.copyWith(
        email: profile['email'] ?? state.email,
        fullName: profile['fullName'] ?? state.fullName,
      );
    }
  }

  Future<bool> login(String email, String password, {String role = "user"}) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
      'role': role.toLowerCase(),
    });

    if (res != null && res['access_token'] != null) {
      final token = res['access_token'];
      ApiClient.setAuthToken(token);
      await LocalStorageService.saveAuthToken(token);
      final user = res['user'];
      final String finalEmail = user['email'] ?? email;
      final String finalName = user['full_name'] ?? "Alex Morgan";
      final String finalRole = user['role'] ?? role;

      await LocalStorageService.saveUserProfile(email: finalEmail, fullName: finalName);

      state = state.copyWith(
        isAuthenticated: true,
        email: finalEmail,
        fullName: finalName,
        role: finalRole,
        isLoading: false,
      );
      return true;
    } else {
      final String errMsg = (res != null && res['error'] != null)
          ? res['error']
          : "Your account is not registered for this role.";
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: errMsg,
      );
      return false;
    }
  }

  Future<bool> register(String email, String fullName, String password, {String role = "user"}) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await ApiClient.post('/auth/register', {
      'email': email,
      'full_name': fullName,
      'password': password,
      'role': role,
    });

    String finalRole = role;

    if (res != null && res['access_token'] != null) {
      final token = res['access_token'];
      ApiClient.setAuthToken(token);
      await LocalStorageService.saveAuthToken(token);
      if (res['user'] != null && res['user']['role'] != null) {
        finalRole = res['user']['role'];
      }
    }

    await LocalStorageService.saveUserProfile(email: email, fullName: fullName);

    state = state.copyWith(
      isAuthenticated: true,
      email: email,
      fullName: fullName,
      role: finalRole,
      isLoading: false,
    );
    return true;
  }

  Future<void> biometricLogin() async {
    state = state.copyWith(isLoading: true);
    final res = await ApiClient.post('/auth/biometric-login', {});
    String finalRole = "user";
    if (res != null && res['access_token'] != null) {
      ApiClient.setAuthToken(res['access_token']);
      await LocalStorageService.saveAuthToken(res['access_token']);
      if (res['user'] != null && res['user']['role'] != null) {
        finalRole = res['user']['role'];
      }
    }
    await LocalStorageService.saveUserProfile(email: "demo@finsight.ai", fullName: "Alex Morgan");
    state = state.copyWith(
      isAuthenticated: true,
      email: "demo@finsight.ai",
      fullName: "Alex Morgan",
      role: finalRole,
      isLoading: false,
    );
  }

  Future<void> logout() async {
    ApiClient.setAuthToken('');
    await LocalStorageService.clearAllUserData();
    state = AuthState(isAuthenticated: false, email: null, fullName: null, role: 'user');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
