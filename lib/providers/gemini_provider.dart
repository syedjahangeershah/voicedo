import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:testy/providers/gemini_tools_provider.dart';

import '../firebase_options.dart';
import 'system_prompt_provider.dart';

class GeminiProvider extends ChangeNotifier {
  FirebaseApp? _firebaseApp;
  GenerativeModel? _geminiModel;
  ChatSession? _chatSession;

  bool _isInitializing = false;
  String? _error;

  // Getters
  FirebaseApp? get firebaseApp => _firebaseApp;

  GenerativeModel? get geminiModel => _geminiModel;

  ChatSession? get chatSession => _chatSession;

  bool get isInitializing => _isInitializing;

  String? get error => _error;

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

  // Initialize Gemini Model
  Future<GenerativeModel> initializeGeminiModel(
    SystemPromptProvider systemPromptProvider,
    GeminiToolsProvider geminiToolsProvider,
  ) async {
    if (_geminiModel != null) return _geminiModel!;

    try {
      _isInitializing = true;
      _error = null;
      notifyListeners();

      // Ensure Firebase is initialized
      await initializeFirebaseApp();

      // Get system prompt
      final systemPrompt = await systemPromptProvider.getSystemPrompt();

      // Get gemini tools
      final geminiTools = geminiToolsProvider.getGeminiTools();

      _geminiModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        systemInstruction: Content.system(systemPrompt),
        tools: geminiTools.tools,
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

  // Initialize all components
  Future<void> initializeAll(
    SystemPromptProvider systemPromptProvider,
    GeminiToolsProvider geminiToolsProvider,
  ) async {
    await initializeChatSession(systemPromptProvider, geminiToolsProvider);
  }

  // Reset/Clear all data
  void reset() {
    _firebaseApp = null;
    _geminiModel = null;
    _chatSession = null;
    _error = null;
    _isInitializing = false;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    reset();
    super.dispose();
  }
}
