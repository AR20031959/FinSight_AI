import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class BackendLauncher {
  static bool _hasAttemptedLaunch = false;

  /// Ensures the FastAPI backend is running and reachable.
  /// On desktop (Windows/Linux/macOS), if the backend is down, it automatically
  /// launches the Python server in the background and waits for it to become ready.
  static Future<bool> ensureRunning({Function(String status)? onStatusUpdate}) async {
    onStatusUpdate?.call("Connecting to FinSight backend...");

    // 1. Initial health check
    if (await ApiClient.checkHealth()) {
      onStatusUpdate?.call("Connected to backend engine.");
      return true;
    }

    // 2. On Desktop, auto-spawn FastAPI if not running
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS) && !_hasAttemptedLaunch) {
      _hasAttemptedLaunch = true;
      onStatusUpdate?.call("Launching FinSight AI backend server...");

      try {
        final pythonCandidates = [
          '..\\.venv\\Scripts\\python.exe',
          '.venv\\Scripts\\python.exe',
          'd:\\FINSIGHT_AI\\.venv\\Scripts\\python.exe',
          '..\\.venv\\bin\\python',
          '.venv\\bin\\python',
          'python',
        ];

        final backendCandidates = [
          '..\\backend',
          'backend',
          'd:\\FINSIGHT_AI\\backend',
          '../backend',
        ];

        String? selectedPython;
        for (final p in pythonCandidates) {
          if (p == 'python') {
            selectedPython = p;
            break;
          }
          if (File(p).existsSync()) {
            selectedPython = File(p).absolute.path;
            break;
          }
        }

        String? selectedBackend;
        for (final b in backendCandidates) {
          if (Directory(b).existsSync()) {
            final mainPy = File('$b/app/main.py');
            final mainPyWin = File('$b\\app\\main.py');
            if (mainPy.existsSync() || mainPyWin.existsSync()) {
              selectedBackend = Directory(b).absolute.path;
              break;
            }
          }
        }

        if (selectedPython != null && selectedBackend != null) {
          debugPrint("[FinSight] Spawning backend server via: $selectedPython in $selectedBackend");
          await Process.start(
            selectedPython,
            ['-m', 'uvicorn', 'app.main:app', '--host', '0.0.0.0', '--port', '8000'],
            workingDirectory: selectedBackend,
            mode: ProcessStartMode.detached,
          );
        }
      } catch (e) {
        debugPrint("[FinSight] Auto-spawn attempt failed: $e");
      }
    }

    // 3. Wait up to 6 seconds for backend to become ready
    for (int i = 0; i < 12; i++) {
      onStatusUpdate?.call("Waiting for backend engine... (${i + 1}s)");
      await Future.delayed(const Duration(milliseconds: 500));
      if (await ApiClient.checkHealth()) {
        onStatusUpdate?.call("Connected!");
        return true;
      }
    }

    return false;
  }
}
