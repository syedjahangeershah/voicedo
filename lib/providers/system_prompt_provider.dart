import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemPromptProvider extends ChangeNotifier {
  String? _systemPrompt;
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get systemPrompt => _systemPrompt;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoaded => _systemPrompt != null;

  // Load system prompt from assets
  Future<String> getSystemPrompt() async {
    if (_systemPrompt != null) return _systemPrompt!;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _systemPrompt = await rootBundle.loadString('assets/system_prompt.md');

      return _systemPrompt!;
    } catch (e) {
      _error = 'Failed to load system prompt: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reload system prompt
  Future<String> reloadSystemPrompt() async {
    _systemPrompt = null;
    return await getSystemPrompt();
  }

  // Update system prompt manually (for testing/development)
  void updateSystemPrompt(String prompt) {
    _systemPrompt = prompt;
    _error = null;
    notifyListeners();
  }

  // Clear system prompt
  void clearSystemPrompt() {
    _systemPrompt = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    clearSystemPrompt();
    super.dispose();
  }
}