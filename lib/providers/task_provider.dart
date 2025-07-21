import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testy/models/chat_message.dart';
import 'package:testy/models/task.dart';
import 'package:testy/services/firebase_service.dart';
import 'package:testy/services/gemini_chat_service.dart';
import 'package:testy/services/voice_service.dart';

class TaskProvider extends ChangeNotifier {
  // Services
  VoiceService? _voiceService;
  GeminiChatService? _geminiChatService;
  FirebaseService? _firebaseService;

  List<TaskModel> _tasks = [];
  final List<ChatMessage> _messages = [];
  StreamSubscription<QuerySnapshot>? _tasksSubscription;

  bool _isListeningToTasks = false;
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

  bool get isListeningToTasks => _isListeningToTasks;

  bool get isRecording => _isRecording;

  bool get isProcessing => _isProcessing;

  bool get isEmpty => _tasks.isEmpty;

  void setServices(
    VoiceService voiceService,
    GeminiChatService geminiChatService,
    FirebaseService firebaseService,
  ) {
    _voiceService = voiceService;
    _geminiChatService = geminiChatService;
    _firebaseService = firebaseService;

    _voiceService?.setErrorCallback(_handleVoiceError);
    _geminiChatService?.setErrorCallback(_handleGeminiError);

    // Listen to voice service state changes
    _listenToVoiceServiceChanges();
  }

  // Start listening to tasks
  Future<void> startListeningToTasks() async {
    if (_firebaseService?.currentUserId == null || _isListeningToTasks) return;

    try {
      debugPrint(
        '🔄 Starting real-time task listener for user: ${_firebaseService?.currentUserId}',
      );

      _isListeningToTasks = true;

      // Listen to tasks collection for current user
      final tasksRef = FirebaseFirestore.instance
          .collection('tasks')
          .doc(_firebaseService!.currentUserId)
          .collection('tasks');

      _tasksSubscription = tasksRef.snapshots().listen(
        (QuerySnapshot snapshot) {
          _handleTasksSnapshot(snapshot);
        },
        onError: (error) {
          debugPrint('❌ Task listener error: $error');
          addSystemErrorMessage('Task sync failed: $error');
        },
      );

      debugPrint('✅ Task listener started successfully');
    } catch (e) {
      debugPrint('❌ Failed to start task listener: $e');
      addSystemErrorMessage('Failed to sync tasks: $e');
      _isListeningToTasks = false;
    }
  }

  void _handleTasksSnapshot(QuerySnapshot snapshot) {
    try {
      debugPrint('🔄 Received ${snapshot.docs.length} tasks from Firestore');

      final firestoreTasks = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['scheduledTime'] is Timestamp) {
          data['scheduledTime'] = (data['scheduledTime'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }

        return TaskModel.fromJson(
          data,
          status: _parseTaskStatus(data['status']),
        );
      }).toList();

      // Update local tasks array
      _tasks = firestoreTasks;

      debugPrint('✅ Updated local tasks: ${_tasks.length} tasks');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error processing task snapshot: $e \n$stackTrace');
      addSystemErrorMessage('Failed to process task updates: $e');
    }
  }

  // Stop listening to tasks
  void stopListeningToTasks() {
    if (_tasksSubscription != null) {
      debugPrint('🛑 Stopping task listener');
      _tasksSubscription!.cancel();
      _tasksSubscription = null;
      _isListeningToTasks = false;
      notifyListeners();
    }
  }

  void _handleVoiceError(String errorMessage) {
    addSystemErrorMessage('Voice Error -> $errorMessage');
  }

  void _handleGeminiError(String errorMessage) {
    addSystemErrorMessage('AI Error -> $errorMessage');
  }

  // Listen to voice service state changes
  void _listenToVoiceServiceChanges() {
    _voiceService?.addListener(() {
      // If voice service has an error, stop recording
      if (_voiceService!.error != null && _isRecording) {
        debugPrint('❌ Voice service error detected, stopping recording UI');
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
    _messages.add(
      ChatMessage(
        text: 'System: $errorText',
        messageType: MessageType.system,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
    debugPrint('🔴 System error added to chat: $errorText');
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> addTask(TaskModel task) async {
    try {
      if (_firebaseService?.currentUserId == null) {
        addSystemErrorMessage('User not authenticated. Cannot create task.');
        return;
      }

      debugPrint('💾 Creating task in Firestore: ${task.title}');

      // Save to Firestore
      final taskRef = FirebaseFirestore.instance
          .collection('tasks')
          .doc(_firebaseService!.currentUserId)
          .collection('tasks')
          .doc();
      final taskData = {
        'id': taskRef.id,
        'title': task.title,
        'description': task.description,
        'scheduledTime': Timestamp.fromDate(task.scheduledTime),
        'status': task.status.name,
        'createdAt': Timestamp.fromDate(task.createdAt),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      await taskRef.set(taskData);

      debugPrint('✅ Task created in Firestore: ${task.title}');

      // Notify Gemini about task creation for context synchronization
      // Real-time listener will automatically update local _tasks array
      Future.delayed(const Duration(seconds: 3), () {
        _notifyGeminiTaskOperation('created', {
          'id': taskRef.id,
          'title': task.title,
          'description': task.description,
          'scheduled_time': task.scheduledTime.toIso8601String(),
          'status': task.status.name,
          'created_at': task.createdAt.toIso8601String(),
        });
      });
    } catch (e) {
      debugPrint('❌ Error creating task in Firestore: $e');
      addSystemErrorMessage('Failed to create task: $e');
    }
  }

  // Update task in Firestore (supports both ID and task number)
  Future<void> updateTask({
    String? id,
    int? number,
    String? title,
    String? description,
    DateTime? scheduledTime,
    TaskStatus? status,
  }) async {
    try {
      // Find task index
      int taskIndex;
      if (number != null) {
        debugPrint('🔢 Updating task by number: $number');

        if (number < 1 || number > _tasks.length) {
          addSystemErrorMessage('Invalid task number. You have ${_tasks.length} tasks (1-${_tasks.length}).');
          return;
        }
        taskIndex = number - 1;
      } else {
        debugPrint('🆔 Updating task by ID: $id');
        taskIndex = _tasks.indexWhere((task) => task.id == id);

      }

      final taskToUpdate = _tasks[taskIndex];
      final oldTask = TaskModel.fromJson(taskToUpdate.toJson());

      debugPrint('📝 Updating task in Firestore: ${taskToUpdate.title}');

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (scheduledTime != null) updateData['scheduledTime'] = scheduledTime.toIso8601String();
      if (status != null) updateData['status'] = status.name;

      // Update in Firestore using the task ID
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(_firebaseService!.currentUserId)
          .collection('tasks')
          .doc(taskToUpdate.id)
          .update(updateData);

      debugPrint('✅ Task updated in Firestore: ${taskToUpdate.title}');

      // Notify Gemini about task update for context synchronization
      // Real-time listener will automatically update local _tasks array
      Future.delayed(const Duration(seconds: 3), () {
        _notifyGeminiTaskOperation('updated', {
          'id': taskToUpdate.id,
          'title': title ?? taskToUpdate.title,
          'description': description ?? taskToUpdate.description,
          'scheduled_time': (scheduledTime ?? taskToUpdate.scheduledTime).toIso8601String(),
          'status': (status ?? taskToUpdate.status).name,
          'previous_title': oldTask.title,
          'previous_description': oldTask.description,
          'previous_scheduled_time': oldTask.scheduledTime.toIso8601String(),
          'previous_status': oldTask.status.name,
        });
      });

    } catch (e) {
      debugPrint('❌ Error updating task in Firestore: $e');
      addSystemErrorMessage('Failed to update task: $e');
    }
  }

  Future<void> deleteTask({String? id, int? number}) async {
    try {
      // Find task index
      int taskIndex;
      if (number != null) {
        // User provided task number (1-based index)
        debugPrint('🔢 Deleting task by number: $number');

        if (number < 1 || number > _tasks.length) {
          addSystemErrorMessage(
            'Invalid task number. You have ${_tasks.length} tasks (1-${_tasks.length}).',
          );
          return;
        }

        taskIndex = number - 1; // Convert to 0-based index
      } else {
        // User provided task ID
        debugPrint('🆔 Deleting task by ID: $id');
        taskIndex = _tasks.indexWhere((task) => task.id == id);
      }

      final taskToDelete = _tasks[taskIndex];
      debugPrint('🗑️ Deleting task from Firestore: ${taskToDelete.title}');

      // Delete from Firestore using the task ID
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(_firebaseService!.currentUserId)
          .collection('tasks')
          .doc(taskToDelete.id) // Always use the actual Firestore ID
          .delete();

      debugPrint('✅ Task deleted from Firestore: ${taskToDelete.title}');

      // Notify Gemini about task deletion for context synchronization
      Future.delayed(const Duration(seconds: 3), () {
        _notifyGeminiTaskOperation('deleted', {
          'id': taskToDelete.id,
          'title': taskToDelete.title,
          'description': taskToDelete.description,
          'scheduled_time': taskToDelete.scheduledTime.toIso8601String(),
          'status': taskToDelete.status.name,
        });
      });
    } catch (e) {
      debugPrint('❌ Error deleting task from Firestore: $e');
      addSystemErrorMessage('Failed to delete task: $e');
    }
  }

  Future<void> updateUserName(String newName) async {
    try {
      final trimmedName = newName.trim();
      debugPrint('👤 Updating user name to: $trimmedName');

      // Update name in Firestore users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseService!.currentUserId)
          .update({'name': trimmedName});

      // Update the name in FirebaseService as well
      await _firebaseService!.updateUserName(trimmedName);

      debugPrint('✅ User name updated successfully to: $trimmedName');

      Future.delayed(const Duration(seconds: 3), () {
        _notifyGeminiTaskOperation('user_name_updated', {
          'user_id': _firebaseService!.currentUserId,
          'new_name': trimmedName,
        });
      });
    } catch (e) {
      debugPrint('❌ Error updating user name: $e');
      addSystemErrorMessage('Failed to update name: $e');
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
        debugPrint('🎤 Voice service started listening');
      } catch (e) {
        debugPrint('❌ Failed to start voice service: $e');
        addSystemErrorMessage(
          'Voice Error -> ❌ Failed to start voice service: $e',
        );
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
      debugPrint('🛑 Voice service stopped listening');
    } catch (e) {
      debugPrint('❌ Failed to stop voice service: $e');
      addSystemErrorMessage(
        'Voice Error -> ❌ Failed to stop voice service: $e',
      );
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
        debugPrint('⚠️ No speech detected');
        addSystemErrorMessage('⚠️ No speech detected. Please try again.');
        return 'No speech detected. Please try again.';
      }

      debugPrint('🎤 Speech recognized: $speechText');
      addMessage(speechText, MessageType.user);

      // Send to Gemini for processing
      if (_geminiChatService != null) {
        debugPrint('📤 Sending to model: ${_geminiChatService!.currentModelId}');
        final response = await _geminiChatService!.sendMessage(speechText);

        addMessage(
          response ?? 'Task processed successfully!',
          MessageType.assistant,
        );

        debugPrint('🤖 Gemini response: $response');
        return response ?? 'Task processed successfully!';
      } else {
        debugPrint('❌ Gemini chat service not available');
        return 'Chat service not available';
      }
    } catch (e) {
      debugPrint('❌ Error processing voice command: $e');
      addSystemErrorMessage('Voice processing failed: $e');
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
    debugPrint('🎯 TaskProvider handling: $functionName');

    try {
      switch (functionName) {
        case 'create_task':
          return _handleCreateTask(arguments);
        case 'update_task':
          return _handleUpdateTask(arguments);
        case 'delete_task':
          return _handleDeleteTask(arguments);
        case 'update_user_name':
          return _handleUpdateUserName(arguments);
        default:
          debugPrint('⚠️ Unknown function: $functionName');
          return null;
      }
    } catch (e) {
      debugPrint('❌ Error in handleGeminiFunctionCall: $e');
      addSystemErrorMessage('Function call error: $e');
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

    debugPrint('✅ Created task: ${task.title}');

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
    final taskNumber = arguments['task_number'] as int?;

    // Validate that either task_id or task_number is provided
    if (taskId == null && taskNumber == null) {
      throw Exception('Either task_id or task_number is required for update');
    }

    final title = arguments['title'] as String?;
    final description = arguments['description'] as String?;
    debugPrint('New date:: ${arguments['scheduled_time']}');
    final scheduledTime = DateTime.tryParse(
      (arguments['scheduled_time'] as String?) ?? "",
    );
    final statusStr = arguments['status'] as String?;

    TaskStatus? status;
    if (statusStr != null) {
      status = _parseTaskStatus(statusStr);
    }

    int taskIndex;
    if (taskNumber != null) {
      updateTask(
        number: taskNumber,
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        status: status,
      );
      taskIndex = taskNumber - 1;
    } else {
      taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex == -1) {
        throw Exception('Task with ID $taskId not found');
      }
      updateTask(
        id: taskId,
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        status: status,
      );
    }

    final updatedTask = _tasks[taskIndex];

    debugPrint('✅ Updated task: ${updatedTask.title}');

    return {
      'task_id': updatedTask.id,
      if (taskNumber != null) 'task_number': taskNumber,
      'title': updatedTask.title,
      'description': updatedTask.description,
      'status': updatedTask.status.name,
      'scheduled_time': updatedTask.scheduledTime.toIso8601String(),
    };
  }

  // Handle delete task from Gemini
  Map<String, dynamic> _handleDeleteTask(Map<String, Object?> arguments) {
    final taskId = arguments['task_id'] as String?;
    final taskNumber = arguments['task_number'] as int?;

    // Validate that either task_id or task_number is provided
    if (taskId == null && taskNumber == null) {
      throw Exception('Either task_id or task_number is required for deletion');
    }

    int taskIndex;
    if (taskNumber != null) {
      deleteTask(number: taskNumber);
      taskIndex = taskNumber - 1;
    } else {
      taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex == -1) {
        throw Exception('Task with ID $taskId not found');
      }
      deleteTask(id: taskId);
    }

    return {
      'task_id': _tasks[taskIndex].id,
      if (taskNumber != null) 'task_number': taskNumber,
      'deleted_title': _tasks[taskIndex].title,
      // 'message': taskNumber != null
      //     ? 'Task #$taskNumber has been deleted successfully'
      //     : 'Task "${_tasks[taskIndex].title}" has been deleted successfully',
    };
  }

  Map<String, dynamic> _handleUpdateUserName(Map<String, Object?> arguments) {

      final newName = arguments['name'] as String?;

      if (newName == null || newName.trim().isEmpty) {
        throw Exception('Name is required and cannot be empty');
      }

      final trimmedName = newName.trim();

      updateUserName(trimmedName);

      debugPrint('✅ User name update requested: $trimmedName');

      return {
        'success': true,
        'new_name': trimmedName,
        'message': 'Your name has been successfully updated to $trimmedName. Nice to meet you, $trimmedName!',
      };
  }

  // Helper method to notify Gemini about task operations
  void _notifyGeminiTaskOperation(
    String operation,
    Map<String, dynamic> taskData,
  ) {
    if (_geminiChatService != null) {
      // Don't await to avoid blocking UI operations
      debugPrint('Notifying Gemini about task $operation');
      _geminiChatService!.notifyTaskOperation(operation, taskData).catchError((
        e,
      ) {
        debugPrint('⚠️ Failed to notify Gemini about task $operation: $e');
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

  // Reset all state
  void reset() {
    debugPrint('🔄 Resetting TaskProvider state');

    // Stop listening to tasks
    stopListeningToTasks();

    // Clear all data
    _tasks.clear();
    _messages.clear();

    // Reset state flags
    _isRecording = false;
    _isProcessing = false;
    _isListeningToTasks = false;

    // Cancel subscriptions
    _tasksSubscription?.cancel();
    _tasksSubscription = null;

    notifyListeners();
    debugPrint('✅ TaskProvider state reset complete');
  }

  // Dispose method
  @override
  void dispose() {
    debugPrint('🗑️ Disposing TaskProvider');

    reset();

    super.dispose();
    debugPrint('✅ TaskProvider disposed successfully');
  }
}
