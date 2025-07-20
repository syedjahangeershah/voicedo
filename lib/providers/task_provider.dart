import 'package:flutter/material.dart';
import 'package:testy/models/chat_message.dart';
import 'package:testy/models/task.dart';
import 'package:testy/services/gemini_chat_service.dart';
import 'package:testy/services/voice_service.dart';

class TaskProvider extends ChangeNotifier {
  // Services
  VoiceService? _voiceService;
  GeminiChatService? _geminiChatService;

  final List<TaskModel> _tasks = [];
  final List<ChatMessage> _messages = [];
  bool _isRecording = false;
  bool _isProcessing = false;

  List<TaskModel> get tasks => List.unmodifiable(_tasks);

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  List<TaskModel> get pendingTasks =>
      _tasks.where((task) => task.currentStatus == TaskStatus.pending).toList();

  List<TaskModel> get completedTasks =>
      _tasks.where((task) => task.status == TaskStatus.completed).toList();

  List<TaskModel> get overdueTasks =>
      _tasks.where((task) => task.isOverdue).toList();

  bool get isRecording => _isRecording;

  bool get isProcessing => _isProcessing;

  bool get isEmpty => _tasks.isEmpty;

  void setServices(
    VoiceService voiceService,
    GeminiChatService geminiChatService,
  ) {
    _voiceService = voiceService;
    _geminiChatService = geminiChatService;

    // Listen to voice service state changes
    _listenToVoiceServiceChanges();
  }

  // Listen to voice service state changes
  void _listenToVoiceServiceChanges() {
    _voiceService?.addListener(() {
      // If voice service stopped listening due to error, update our state
      // if (_isRecording && (!_voiceService!.isListening)) {
      //   print('🔄 Voice service stopped listening, updating UI state');
      //   _isRecording = false;
      //   notifyListeners();
      // }

      // If voice service has an error, stop recording
      if (_voiceService!.error != null && _isRecording) {
        print('❌ Voice service error detected, stopping recording UI');
        _isRecording = false;
        notifyListeners();
      }
    });
  }

  // Add message to messages array to display messages in Chat box
  void addMessage(String text, MessageType messageType) {
    _messages.add(
      ChatMessage(
        text: text,
        messageType: messageType,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // Add system error message
  void addSystemErrorMessage(String errorText) {
    _messages.add(ChatMessage(
      text: '⚠️ System: $errorText',
      messageType: MessageType.system,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
    print('🔴 System error added to chat: $errorText');
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Task Management
  void addTask(TaskModel task) {
    _tasks.add(task);
    notifyListeners();

    // Notify Gemini about task creation for context synchronization
    Future.delayed(const Duration(seconds: 3), () {
      _notifyGeminiTaskOperation('created', {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'scheduled_time': task.scheduledTime.toIso8601String(),
        'status': task.status.name,
        'created_at': task.createdAt.toIso8601String(),
      });
    });
  }

  void updateTask(
    String id, {
    String? title,
    String? description,
    DateTime? scheduledTime,
    TaskStatus? status,
  }) {
    final taskIndex = _tasks.indexWhere((task) => task.id == id);
    if (taskIndex != -1) {
      final oldTask = TaskModel.fromJson(_tasks[taskIndex].toJson());
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        status: status,
      );
      notifyListeners();

      // Notify Gemini about task update for context synchronization
      final updatedTask = _tasks[taskIndex];
      Future.delayed(const Duration(seconds: 3), () {
        _notifyGeminiTaskOperation('updated', {
          'id': updatedTask.id,
          'title': updatedTask.title,
          'description': updatedTask.description,
          'scheduled_time': updatedTask.scheduledTime.toIso8601String(),
          'status': updatedTask.status.name,
          'previous_title': oldTask.title,
          'previous_description': oldTask.title,
          'previous_scheduled_time': oldTask.title,
          'previous_status': oldTask.status.name,
        });
      });
    }
  }

  void deleteTask(String id) {
    final taskIndex = _tasks.indexWhere((task) => task.id == id);
    if (taskIndex != -1) {
      final deletedTask = TaskModel.fromJson(_tasks[taskIndex].toJson());
      _tasks.removeWhere((task) => task.id == id);
      notifyListeners();

      // Notify Gemini about task deletion for context synchronization
      Future.delayed(const Duration(seconds: 3), () {
        _notifyGeminiTaskOperation('deleted', {
          'id': deletedTask.id,
          'title': deletedTask.title,
          'description': deletedTask.description,
          'scheduled_time': deletedTask.scheduledTime.toIso8601String(),
          'status': deletedTask.status.name,
        });
      });
    }
  }

  Future<void> startRecording() async {
    if (_isProcessing) return;
    _isRecording = true;
    notifyListeners();

    // Actually start voice service listening
    if (_voiceService != null) {
      try {
        await _voiceService!.startListening();
        print('🎤 Voice service started listening');
      } catch (e) {
        print('❌ Failed to start voice service: $e');
        _isRecording = false;
        notifyListeners();
      }
    }
  }

  Future<void> stopRecording() async {
    _isRecording = false;
    notifyListeners();

    // Actually stop voice service
    try {
      await _voiceService!.stopListening();
      print('🛑 Voice service stopped listening');
    } catch (e) {
      print('❌ Failed to stop voice service: $e');
    }
  }

  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  Future<String?> processVoiceCommand() async {
    if (!_isRecording) return null;

    await stopRecording();
    _isProcessing = true;
    notifyListeners();

    try {
      // Get speech text from voice service
      final speechText = _voiceService?.lastWords ?? '';

      if (speechText.isEmpty) {
        print('⚠️ No speech detected');
        return 'No speech detected. Please try again.';
      }

      print('🎤 Speech recognized: $speechText');
      addMessage(speechText, MessageType.user);

      // Send to Gemini for processing
      if (_geminiChatService != null) {
        final response = await _geminiChatService!.sendMessage(speechText);

        addMessage(
          response ?? 'Task processed successfully!',
          MessageType.assistant,
        );

        print('🤖 Gemini response: $response');
        return response ?? 'Task processed successfully!';
      } else {
        print('❌ Gemini chat service not available');
        return 'Chat service not available';
      }
    } catch (e) {
      print('❌ Error processing voice command: $e');
      return 'Voice processing failed: $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Gemini Function Handlers
  Map<String, dynamic>? handleGeminiFunctionCall(
    String functionName,
    Map<String, Object?> arguments,
  ) {
    print('🎯 TaskProvider handling: $functionName');

    try {
      switch (functionName) {
        case 'create_task':
          return _handleCreateTask(arguments);
        case 'update_task':
          return _handleUpdateTask(arguments);
        case 'delete_task':
          return _handleDeleteTask(arguments);
        default:
          print('⚠️ Unknown function: $functionName');
          return null;
      }
    } catch (e) {
      print('❌ Error in handleGeminiFunctionCall: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Handle create task from Gemini
  Map<String, dynamic> _handleCreateTask(Map<String, Object?> arguments) {
    final title = arguments['title'] as String? ?? 'Untitled Task';
    final description = arguments['description'] as String? ?? '';
    final scheduledTime =
        DateTime.tryParse((arguments['scheduled_time'] as String?) ?? "") ??
        DateTime.now().add(Duration(hours: 1));
    final priority = arguments['priority'] as String? ?? 'medium';

    final task = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      scheduledTime: scheduledTime,
    );

    addTask(task);

    print('✅ Created task: ${task.title}');

    return {
      'task_id': task.id,
      'title': task.title,
      'description': task.description,
      'scheduled_time': task.scheduledTime.toIso8601String(),
      'priority': priority,
    };
  }

  // Handle update task from Gemini
  Map<String, dynamic> _handleUpdateTask(Map<String, Object?> arguments) {
    final taskId = arguments['task_id'] as String?;
    if (taskId == null) {
      throw Exception('Task ID is required for updates');
    }

    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) {
      throw Exception('Task with ID $taskId not found');
    }

    final title = arguments['title'] as String?;
    final description = arguments['description'] as String?;
    final scheduledTime = DateTime.tryParse(
      (arguments['scheduled_time'] as String?) ?? "",
    );
    final statusStr = arguments['status'] as String?;

    TaskStatus? status;
    if (statusStr != null) {
      status = _parseTaskStatus(statusStr);
    }

    updateTask(
      taskId,
      title: title,
      description: description,
      scheduledTime: scheduledTime,
      status: status,
    );

    final updatedTask = _tasks[taskIndex];

    print('✅ Updated task: ${updatedTask.title}');

    return {
      'task_id': taskId,
      'title': updatedTask.title,
      'description': updatedTask.description,
      'status': updatedTask.status.name,
      'scheduled_time': updatedTask.scheduledTime.toIso8601String(),
    };
  }

  // Handle delete task from Gemini
  Map<String, dynamic> _handleDeleteTask(Map<String, Object?> arguments) {
    final taskId = arguments['task_id'] as String?;
    if (taskId == null) {
      throw Exception('Task ID is required for deletion');
    }

    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) {
      throw Exception('Task with ID $taskId not found');
    }

    final task = _tasks[taskIndex];
    final taskTitle = task.title;

    deleteTask(taskId);

    print('✅ Deleted task: $taskTitle');

    return {
      'task_id': taskId,
      'deleted_title': taskTitle,
      'message': 'Task "$taskTitle" has been deleted successfully',
    };
  }

  // Helper method to notify Gemini about task operations
  void _notifyGeminiTaskOperation(
    String operation,
    Map<String, dynamic> taskData,
  ) {
    if (_geminiChatService != null) {
      // Don't await to avoid blocking UI operations
      print('Notifying Gemini about task $operation');
      _geminiChatService!.notifyTaskOperation(operation, taskData).catchError((
        e,
      ) {
        print('⚠️ Failed to notify Gemini about task $operation: $e');
      });
    }
  }

  // Helper method to parse task status
  TaskStatus _parseTaskStatus(String statusStr) {
    switch (statusStr.toLowerCase().trim()) {
      case 'pending':
      case 'todo':
      case 'new':
        return TaskStatus.pending;
      case 'inprogress':
      case 'in_progress':
      case 'in-progress':
      case 'working':
      case 'active':
        return TaskStatus.inProgress;
      case 'completed':
      case 'done':
      case 'finished':
        return TaskStatus.completed;
      case 'overdue':
      case 'late':
      case 'expired':
        return TaskStatus.overdue;
      default:
        return TaskStatus.pending;
    }
  }
}
