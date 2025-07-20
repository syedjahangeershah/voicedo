import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:testy/models/gemini_model_config.dart';
import 'package:testy/providers/gemini_tools_provider.dart';

import '../firebase_options.dart';
import 'system_prompt_provider.dart';

class GeminiProvider extends ChangeNotifier {
  FirebaseApp? _firebaseApp;
  GenerativeModel? _geminiModel;
  ChatSession? _chatSession;

  bool _isInitializing = false;
  String? _error;

  // Current selected model
  String _currentModelId = 'gemini-2.5-flash'; // Default model

  // Available models
  static const List<GeminiModelConfig> availableModels = [
    GeminiModelConfig(
      name: 'Gemini 2.5 Pro',
      modelId: 'gemini-2.5-pro',
      displayName: 'Gemini 2.5 Pro',
    ),
    GeminiModelConfig(
      name: 'Gemini 2.5 Flash',
      modelId: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash',
    ),
    GeminiModelConfig(
      name: 'Gemini 2.0 Flash',
      modelId: 'gemini-2.0-flash-001',
      displayName: 'Gemini 2.0 Flash',
    ),
    GeminiModelConfig(
      name: 'Gemini 2.0 Flash‑Lite',
      modelId: 'gemini-2.0-flash-lite-001',
      displayName: 'Gemini 2.0 Flash‑Lite',
    ),
  ];

  // Getters
  FirebaseApp? get firebaseApp => _firebaseApp;
  GenerativeModel? get geminiModel => _geminiModel;
  ChatSession? get chatSession => _chatSession;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  String get currentModelId => _currentModelId;

  // Get current model config
  GeminiModelConfig get currentModel {
    return availableModels.firstWhere(
          (model) => model.modelId == _currentModelId,
      orElse: () => availableModels[1],
    );
  }

  // Get available models list
  List<GeminiModelConfig> get models => availableModels;

  bool get isInitialized =>
      _firebaseApp != null && _geminiModel != null && _chatSession != null;

  // Initialize Firebase App
  Future<FirebaseApp> initializeFirebaseApp() async {
    if (_firebaseApp != null) return _firebaseApp!;

    try {
      _isInitializing = true;
      _error = null;
      notifyListeners();

      _firebaseApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      return _firebaseApp!;
    } catch (e) {
      _error = 'Failed to initialize Firebase: $e';
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Initialize Gemini Model with specific model ID
  Future<GenerativeModel> _createGeminiModel(
      String modelId,
      SystemPromptProvider systemPromptProvider,
      GeminiToolsProvider geminiToolsProvider,
      ) async {
    try {
      // Ensure Firebase is initialized
      await initializeFirebaseApp();

      // Get system prompt
      final systemPrompt = await systemPromptProvider.getSystemPrompt();

      // Get gemini tools
      final geminiTools = geminiToolsProvider.getGeminiTools();

      return FirebaseAI.googleAI().generativeModel(
        model: modelId,
        systemInstruction: Content.system(systemPrompt),
        tools: geminiTools.tools,
      );
    } catch (e) {
      _error = 'Failed to create Gemini model ($modelId): $e';
      rethrow;
    }
  }

  // Initialize Gemini Model with current model
  Future<GenerativeModel> initializeGeminiModel(
      SystemPromptProvider systemPromptProvider,
      GeminiToolsProvider geminiToolsProvider,
      ) async {
    if (_geminiModel != null) return _geminiModel!;

    try {
      _isInitializing = true;
      _error = null;
      notifyListeners();

      _geminiModel = await _createGeminiModel(
        _currentModelId,
        systemPromptProvider,
        geminiToolsProvider,
      );

      return _geminiModel!;
    } catch (e) {
      _error = 'Failed to initialize Gemini model: $e';
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Initialize Chat Session
  Future<ChatSession> initializeChatSession(
      SystemPromptProvider systemPromptProvider,
      GeminiToolsProvider geminiToolsProvider,
      ) async {
    if (_chatSession != null) return _chatSession!;

    try {
      _isInitializing = true;
      _error = null;
      notifyListeners();

      // Ensure model is initialized
      final model = await initializeGeminiModel(
        systemPromptProvider,
        geminiToolsProvider,
      );

      _chatSession = model.startChat();

      return _chatSession!;
    } catch (e) {
      _error = 'Failed to initialize chat session: $e';
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Switch to a different model
  Future<void> switchModel(
      String newModelId,
      SystemPromptProvider systemPromptProvider,
      GeminiToolsProvider geminiToolsProvider,
      ) async {
    try {
      _isInitializing = true;
      _error = null;
      notifyListeners();

      // Validate model ID
      final isValidModel = availableModels.any(
            (model) => model.modelId == newModelId,
      );

      if (!isValidModel) {
        throw Exception('Invalid model ID: $newModelId');
      }

      // If it's the same model, no need to switch
      if (_currentModelId == newModelId && _chatSession != null) {
        return;
      }

      // Update current model ID
      _currentModelId = newModelId;

      // Clear existing model and chat session
      _geminiModel = null;
      _chatSession = null;

      // Create new model with the new model ID
      _geminiModel = await _createGeminiModel(
        newModelId,
        systemPromptProvider,
        geminiToolsProvider,
      );

      // Start new chat session
      _chatSession = _geminiModel!.startChat();

      debugPrint('Successfully switched to model: $newModelId');
    } catch (e) {
      _error = 'Failed to switch model to $newModelId: $e';
      debugPrint('Error switching model: $e');
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Switch model by config
  Future<void> switchModelByConfig(
      GeminiModelConfig modelConfig,
      SystemPromptProvider systemPromptProvider,
      GeminiToolsProvider geminiToolsProvider,
      ) async {
    await switchModel(
      modelConfig.modelId,
      systemPromptProvider,
      geminiToolsProvider,
    );
  }

  // Initialize all components
  Future<void> initializeAll(
      SystemPromptProvider systemPromptProvider,
      GeminiToolsProvider geminiToolsProvider,
      ) async {
    await initializeChatSession(systemPromptProvider, geminiToolsProvider);
  }

  // Set default model (before initialization)
  void setDefaultModel(String modelId) {
    final isValidModel = availableModels.any(
          (model) => model.modelId == modelId,
    );

    if (isValidModel) {
      _currentModelId = modelId;
      notifyListeners();
    } else {
      throw Exception('Invalid model ID: $modelId');
    }
  }

  // Get model display name by ID
  String getModelDisplayName(String modelId) {
    final model = availableModels.firstWhere(
          (model) => model.modelId == modelId,
      orElse: () => availableModels[1], // Default
    );
    return model.displayName;
  }

  // Check if model is currently selected
  bool isModelSelected(String modelId) {
    return _currentModelId == modelId;
  }

  // Reset/Clear all data
  void reset() {
    _firebaseApp = null;
    _geminiModel = null;
    _chatSession = null;
    _error = null;
    _isInitializing = false;
    // Keep the current model ID, don't reset it
    notifyListeners();
  }

  // Reset and switch model (clears chat history)
  Future<void> resetAndSwitchModel(
      String newModelId,
      SystemPromptProvider systemPromptProvider,
      GeminiToolsProvider geminiToolsProvider,
      ) async {
    // Clear everything except Firebase app
    _geminiModel = null;
    _chatSession = null;
    _error = null;

    // Switch to new model
    await switchModel(newModelId, systemPromptProvider, geminiToolsProvider);
  }

  // Dispose
  @override
  void dispose() {
    reset();
    super.dispose();
  }
}