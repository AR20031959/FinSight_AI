import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../providers/ai_provider.dart';

class LocalStorageService {
  static const String _keyTransactions = 'finsight_transactions';
  static const String _keyAuthToken = 'finsight_auth_token';
  static const String _keyUserEmail = 'finsight_user_email';
  static const String _keyUserFullName = 'finsight_user_fullname';
  static const String _keyChatHistory = 'finsight_chat_history';
  static const String _keyBaseUrl = 'finsight_base_url';

  /// Save transactions to device local storage
  static Future<void> saveTransactions(List<TransactionModel> txs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = txs.map((t) => t.toJson()).toList();
    await prefs.setString(_keyTransactions, jsonEncode(jsonList));
  }

  /// Load transactions from device local storage
  static Future<List<TransactionModel>?> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyTransactions);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) => TransactionModel.fromJson(item)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Save auth token to device local storage
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token);
  }

  /// Load auth token from device local storage
  static Future<String?> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  /// Save user profile locally
  static Future<void> saveUserProfile({required String email, required String fullName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserFullName, fullName);
  }

  /// Load user profile from device local storage
  static Future<Map<String, String?>> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyUserEmail),
      'fullName': prefs.getString(_keyUserFullName),
    };
  }

  /// Save chat messages locally
  static Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final list = messages.map((m) => {
      'text': m.text,
      'isUser': m.isUser,
      'timestamp': m.timestamp.toIso8601String(),
    }).toList();
    await prefs.setString(_keyChatHistory, jsonEncode(list));
  }

  /// Load chat messages from local device storage
  static Future<List<ChatMessage>?> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyChatHistory);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((m) => ChatMessage(
        text: m['text'] ?? '',
        isUser: m['isUser'] ?? false,
        timestamp: m['timestamp'] != null ? DateTime.parse(m['timestamp']) : DateTime.now(),
      )).toList();
    } catch (e) {
      return null;
    }
  }

  /// Save base API URL (e.g. cloud host or custom server IP)
  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url);
  }

  /// Load base API URL with fallback
  static Future<String> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? "http://127.0.0.1:8000/api";
  }

  /// Clear all user-specific data from local device storage on logout
  static Future<void> clearAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyTransactions);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserFullName);
    await prefs.remove(_keyChatHistory);
  }
}
