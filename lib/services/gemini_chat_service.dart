import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

class GeminiChatService extends ChangeNotifier {
  ChatSession? _chatSession;
  Function(String, Map<String, Object?>)? _functionHandler;
  Function(String)? _onSystemError;

  String? _currentModelId;
  String? get currentModelId => _currentModelId;

  bool _isProcessing = false;
  String? _error;
  String? _lastResponse;

  // Getters
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get lastResponse => _lastResponse;
  bool get isInitialized => _chatSession != null;

  // Initialize chat session
  void initializeChatSession(ChatSession chatSession, {String? modelId}) {
    _chatSession = chatSession;
    _currentModelId = modelId;
    _error = null;
    debugPrint('🤖 Chat service initialized with model: $_currentModelId');
    notifyListeners();
  }

  void setErrorCallback(Function(String) onError) {
    _onSystemError = onError;
  }

  // Set function handler for tool calls
  void setFunctionHandler(Function(String, Map<String, Object?>) handler) {
    _functionHandler = handler;
    debugPrint('🔗 Function handler connected to chat service');
  }

  Future<String?> sendMessage(String message) async {
    if (_chatSession == null) {
      _error = 'Chat session not initialized';
      notifyListeners();
      return null;
    }

    try {
      _isProcessing = true;
      _error = null;
      _lastResponse = null;
      notifyListeners();

      debugPrint('📤 Sending message to Gemini: $message');

      // Send message to Gemini
      final response = await _chatSession!.sendMessage(Content.multi([TextPart(message)]));

      String finalResponse = '';

      // Handle initial response text
      if (response.text != null && response.text!.isNotEmpty) {
        finalResponse = response.text!;
        debugPrint('📥 Received text response: ${response.text}');
      }

      debugPrint('Processing:: ${response.functionCalls.length} function calls');

      // Handle function calls ONLY if they exist
      if (response.functionCalls.isNotEmpty) {
        debugPrint('🔧 Processing ${response.functionCalls.length} function calls');
        final functionResponse = await _handleFunctionCalls(response.functionCalls);

        if (functionResponse != null && functionResponse.isNotEmpty) {
          finalResponse = functionResponse;
        }
      } else {
        debugPrint('No function calls - using text response only');
      }

      // Set final response
      _lastResponse = finalResponse.isNotEmpty ? finalResponse : 'Task completed successfully!';

      return _lastResponse;

    } catch (e, stackTrace) {
      debugPrint('❌ Error sending message: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = 'Failed to process request: $e';
      _lastResponse = 'Sorry, error sending message: $e';
      return _lastResponse;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Handle function calls from Gemini
  Future<String?> _handleFunctionCalls(Iterable<FunctionCall> functionCalls) async {
    if (_functionHandler == null) {
      debugPrint('❌ No function handler available');
      return 'Function handler not available.';
    }

    try {
      // Execute all function calls and collect responses
      final functionResponses = <FunctionResponse>[];

      for (final functionCall in functionCalls) {
        debugPrint('🔧 Executing function: ${functionCall.name}');
        debugPrint('📋 Arguments: ${functionCall.args}');

        final result = _functionHandler!(functionCall.name, functionCall.args);

        if (result != null) {
          debugPrint('✅ Function result: $result');
          functionResponses.add(
            FunctionResponse(functionCall.name, result),
          );
        } else {
          debugPrint('⚠️ Function returned null result');
          functionResponses.add(
            FunctionResponse(functionCall.name, {
              'success': false,
              'error': 'Function execution failed',
            }),
          );
        }
      }

      // Send function responses back to Gemini
      if (functionResponses.isNotEmpty) {
        debugPrint('📤 Sending function responses back to Gemini');

        final functionResultResponse = await _chatSession!.sendMessage(
          Content.functionResponses(functionResponses),
        );

        // Return Gemini's response to function results
        if (functionResultResponse.text != null && functionResultResponse.text!.isNotEmpty) {
          debugPrint('📥 Received function result response: ${functionResultResponse.text}');
          return functionResultResponse.text!;
        }
      }

      return null;

    } catch (e, stackTrace) {
      debugPrint('❌ Error handling function calls: $e');
      _onSystemError?.call('❌ Error handling function calls: $e');
      debugPrint('Stack trace: $stackTrace');
      return 'Sorry, I had trouble completing that task.';
    }
  }

  // Notify Gemini about task operations for context synchronization
  Future<void> notifyTaskOperation(String operation, Map<String, dynamic> taskData) async {
    // Simplified notification format for Gemini 2.5 Flash
    String notification;

    switch (operation) {
      case 'created':
        notification = 'System: I just created a task titled "${taskData['title']}" for ${taskData['scheduled_time']}';
        break;
      case 'updated':
        notification = 'System: I updated the task "${taskData['title']}"';
        break;
      case 'deleted':
        notification = 'System: I deleted the task "${taskData['title']}"';
        break;
      case 'user_name_updated':
        notification = 'System: User name changed to "${taskData['new_name']}"';
        break;
      default:
        notification = 'System: Task $operation completed';
    }

    debugPrint('🔔 Notifying Gemini: $notification');
    await sendMessage(notification);
  }

  // Reset service
  void reset() {
    _chatSession = null;
    _functionHandler = null;
    _isProcessing = false;
    _error = null;
    _lastResponse = null;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}