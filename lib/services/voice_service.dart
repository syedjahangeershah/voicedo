import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_speech/flutter_speech.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService extends ChangeNotifier {
  SpeechRecognition? _speech;
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastWords = '';
  String? _error;

  Function(String)? _onSystemError;

  // Getters
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastWords => _lastWords;
  String? get error => _error;

  // Initialize speech recognition
  Future<void> initialize() async {
    try {
      _speech = SpeechRecognition();

      // Check permissions
      final permissionStatus = await Permission.microphone.request();
      if (permissionStatus != PermissionStatus.granted) {
        _error = 'Microphone permission denied';
        notifyListeners();
        return;
      }

      // Set up callbacks
      _speech!.setAvailabilityHandler(_onSpeechAvailability);
      _speech!.setRecognitionStartedHandler(_onRecognitionStarted);
      _speech!.setRecognitionResultHandler(_onRecognitionResult);
      _speech!.setRecognitionCompleteHandler(_onRecognitionComplete);
      _speech!.setErrorHandler(_onSpeechError);

      // Activate speech recognition
      _speech!.activate('en_US').then((result) {
        _isAvailable = result;
        _error = null;
        notifyListeners();
        debugPrint('✅ Speech recognition initialized: $_isAvailable');
      });

    } catch (e) {
      _error = 'Failed to initialize speech recognition: $e';
      debugPrint('❌ Speech initialization error: $e');
      notifyListeners();
    }
  }

  // Start listening
  Future<String?> startListening() async {
    if (!_isAvailable || _speech == null) {
      _error = 'Speech recognition not available';
      notifyListeners();
      return null;
    }

    if (_isListening) {
      debugPrint('⚠️ Already listening');
      return null;
    }

    try {
      _lastWords = '';
      _error = null;
      notifyListeners();

      final completer = Completer<String?>();

      // Override completion handler for this session
      _speech!.setRecognitionCompleteHandler((String result) {
        _onRecognitionComplete(result);
        if (!completer.isCompleted) {
          completer.complete(result.isNotEmpty ? result : null);
        }
      });

      // Start listening
      _speech!.listen();

      debugPrint('🎤 Started listening...');

      // Return the result when recognition completes
      return await completer.future;

    } catch (e) {
      _error = 'Failed to start listening: $e';
      _onSystemError?.call('❌ Failed to start listening: $e');
      debugPrint('❌ Listen error: $e');
      notifyListeners();
      return null;
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_speech != null && _isListening) {
      _speech!.stop();
      debugPrint('🛑 Stopped listening');
    }
  }

  // Cancel listening
  Future<void> cancelListening() async {
    if (_speech != null && _isListening) {
      _speech!.cancel();
      _isListening = false;
      _lastWords = '';
      notifyListeners();
      debugPrint('❌ Cancelled listening');
    }
  }

  // Callback handlers
  void _onSpeechAvailability(bool available) {
    _isAvailable = available;
    notifyListeners();
    debugPrint('🔊 Speech availability: $available');
  }

  void _onRecognitionStarted() {
    _isListening = true;
    _error = null;
    notifyListeners();
    debugPrint('🎙️ Recognition started');
  }

  void _onRecognitionResult(String text) {
    _lastWords = text;
    notifyListeners();
    debugPrint('📝 Recognition result: $text');
  }

  void _onRecognitionComplete(String text) {
    _isListening = false;
    _lastWords = text;
    notifyListeners();
    debugPrint('✅ Recognition complete: $text');
  }


  void setErrorCallback(Function(String) onError) {
    _onSystemError = onError;
  }

  void _onSpeechError() {
    _isListening = false;
    _error = 'Speech recognition error occurred';
    debugPrint('❌ Speech error occurred');

    _onSystemError?.call('Speech recognition failed. Please try again.');

    // Reset speech recognition on error
    debugPrint('🔄 Resetting speech recognition due to error');

    _resetSpeechRecognition();
    notifyListeners();
  }

  // Reset speech recognition when it gets stuck
  Future<void> _resetSpeechRecognition() async {
    try {
      debugPrint('🔄 Resetting speech recognition...');

      // Cancel any ongoing recognition
      if (_speech != null) {
        _speech!.cancel();
      }

      await Future.delayed(Duration(milliseconds: 500));
      _onSystemError?.call('🔄 Resetting speech recognition...');

      // Clear state
      _isListening = false;
      _lastWords = '';
      _error = null;

      // Try to reactivate
      if (_speech != null) {
        _speech!.activate('en_US').then((result) {
          _isAvailable = result;
          notifyListeners();
          debugPrint('✅ Speech recognition reset complete: $_isAvailable');
          _onSystemError?.call('✅ Speech reactivated successfully!');
        }).catchError((e) {
          debugPrint('❌ Failed to reactivate speech: $e');
          _onSystemError?.call('❌ Failed to reactivate speech: $e');
          _error = 'Speech reactivation failed';
          _isAvailable = false;
          notifyListeners();
        });
      }

    } catch (e) {
      debugPrint('❌ Failed to reset speech recognition: $e');
      _onSystemError?.call('❌ Failed to reactivate speech: $e');
      _error = 'Speech recognition reset failed';
      _isAvailable = false;
      notifyListeners();
    }
  }

  // Clean up
  @override
  void dispose() {
    _speech?.stop();
    _speech = null;
    super.dispose();
  }
}