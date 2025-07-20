import 'package:flutter/material.dart';
import '../services/gemini_tools.dart';
import '../providers/task_provider.dart';

class GeminiToolsProvider extends ChangeNotifier {
  late GeminiTools _geminiTools;
  bool _isInitialized = false;
  String? _error;
  TaskProvider? _taskProvider;

  GeminiToolsProvider() {
    _initializeTools();
  }

  // Getters
  GeminiTools get geminiTools => _geminiTools;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // Initialize tools
  void _initializeTools() {
    try {
      _geminiTools = GeminiTools();
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize Gemini tools: $e';
      _isInitialized = false;
    }
    notifyListeners();
  }

  // Set task provider and connect function handler
  void setTaskProvider(TaskProvider taskProvider) {
    _taskProvider = taskProvider;
    _geminiTools.setFunctionHandler(_handleFunctionCall);
    debugPrint('🔗 Connected TaskProvider to GeminiTools');
  }

  // Handle function calls from Gemini
  Map<String, dynamic>? _handleFunctionCall(String functionName, Map<String, Object?> arguments) {
    if (_taskProvider == null) {
      debugPrint('❌ TaskProvider not connected');
      return null;
    }

    debugPrint('🎯 GeminiToolsProvider routing $functionName to TaskProvider');
    return _taskProvider!.handleGeminiFunctionCall(functionName, arguments);
  }

  // Get tools for Gemini model
  GeminiTools getGeminiTools() {
    if (!_isInitialized) {
      throw StateError('GeminiTools not initialized');
    }
    return _geminiTools;
  }

  // Reset tools
  void resetTools() {
    _isInitialized = false;
    _error = null;
    _taskProvider = null;
    notifyListeners();
  }

  @override
  void dispose() {
    resetTools();
    super.dispose();
  }
}