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
    this.isAuthenticated = false,
    this.email,
    this.fullName,
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
  AuthNotifier() : super(AuthState(isLoading: true)) {
    _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    final token = await LocalStorageService.loadAuthToken();
    if (token != null && token.isNotEmpty) {
      ApiClient.setAuthToken(token);
      final res = await ApiClient.get('/auth/me');
      if (res != null && res is Map && res['email'] != null && res['email'] != "demo@finsight.ai") {
        final email = res['email'];
        final name = res['full_name'] ?? "User";
        final role = res['role'] ?? "user";
        await LocalStorageService.saveUserProfile(email: email, fullName: name);
        state = state.copyWith(
          isAuthenticated: true,
          email: email,
          fullName: name,
          role: role,
          isLoading: false,
        );
        return;
      }
    }
    // Invalidate invalid/expired or demo session
    ApiClient.setAuthToken('');
    await LocalStorageService.clearAllUserData();
    state = AuthState(isAuthenticated: false, isLoading: false);
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
      final String finalName = user['full_name'] ?? "User";
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
      final String errMsg = (res != null && res['detail'] != null)
          ? res['detail'].toString()
          : ((res != null && res['error'] != null) ? res['error'].toString() : "Your account is not registered for this role.");
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

  Future<void> logout() async {
    ApiClient.setAuthToken('');
    await LocalStorageService.clearAllUserData();
    state = AuthState(isAuthenticated: false, email: null, fullName: null, role: 'user');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
