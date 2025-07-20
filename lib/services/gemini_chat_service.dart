import 'dart:async';
import 'dart:convert' show json;
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

class GeminiChatService extends ChangeNotifier {
  ChatSession? _chatSession;
  Function(String, Map<String, Object?>)? _functionHandler;

  bool _isProcessing = false;
  String? _error;
  String? _lastResponse;

  // Getters
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get lastResponse => _lastResponse;
  bool get isInitialized => _chatSession != null;

  // Initialize chat session
  void initializeChatSession(ChatSession chatSession) {
    _chatSession = chatSession;
    _error = null;
    notifyListeners();
    print('✅ Gemini chat session initialized');
  }

  // Set function handler for tool calls
  void setFunctionHandler(Function(String, Map<String, Object?>) handler) {
    _functionHandler = handler;
    print('🔗 Function handler connected to chat service');
  }

  // Send message to Gemini (main method for voice commands)
  // Send message to Gemini (main method for voice commands)
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

      print('📤 Sending message to Gemini: $message');

      // Send message to Gemini
      final response = await _chatSession!.sendMessage(Content.text(message));

      String finalResponse = '';

      // Handle initial response text
      if (response.text != null && response.text!.isNotEmpty) {
        finalResponse = response.text!;
        print('📥 Received text response: ${response.text}');
      }

      print('Processing:: ${response.functionCalls.length} function calls');

      // Handle function calls ONLY if they exist
      if (response.functionCalls.isNotEmpty) {
        print('🔧 Processing ${response.functionCalls.length} function calls');
        final functionResponse = await _handleFunctionCalls(response.functionCalls);

        if (functionResponse != null && functionResponse.isNotEmpty) {
          finalResponse = functionResponse;
        }
      } else {
        print('No function calls - using text response only');
      }

      // Set final response
      _lastResponse = finalResponse.isNotEmpty ? finalResponse : 'Task completed successfully!';

      return _lastResponse;

    } catch (e, stackTrace) {
      print('❌ Error sending message: $e');
      print('Stack trace: $stackTrace');
      _error = 'Failed to process request: $e';
      _lastResponse = 'Sorry, I encountered an error. Please try again.';
      return _lastResponse;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Handle function calls from Gemini
  Future<String?> _handleFunctionCalls(Iterable<FunctionCall> functionCalls) async {
    if (_functionHandler == null) {
      print('❌ No function handler available');
      return 'Function handler not available.';
    }

    try {
      // Execute all function calls and collect responses
      final functionResponses = <FunctionResponse>[];

      for (final functionCall in functionCalls) {
        print('🔧 Executing function: ${functionCall.name}');
        print('📋 Arguments: ${functionCall.args}');

        final result = _functionHandler!(functionCall.name, functionCall.args);

        if (result != null) {
          print('✅ Function result: $result');
          functionResponses.add(
            FunctionResponse(functionCall.name, result),
          );
        } else {
          print('⚠️ Function returned null result');
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
        print('📤 Sending function responses back to Gemini');

        final functionResultResponse = await _chatSession!.sendMessage(
          Content.functionResponses(functionResponses),
        );

        // Return Gemini's response to function results
        if (functionResultResponse.text != null && functionResultResponse.text!.isNotEmpty) {
          print('📥 Received function result response: ${functionResultResponse.text}');
          return functionResultResponse.text!;
        }
      }

      return null;

    } catch (e, stackTrace) {
      print('❌ Error handling function calls: $e');
      print('Stack trace: $stackTrace');
      return 'Sorry, I had trouble completing that task.';
    }
  }

  // Notify Gemini about task operations for context synchronization
  Future<void> notifyTaskOperation(String operation, Map<String, dynamic> taskData) async {
    final notification = 'System notification: Task $operation - ${json.encode(taskData)}';
    print('🔔 Notifying Gemini: $notification');
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