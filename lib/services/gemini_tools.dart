import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiTools {
  // Function handler for processing function calls
  Function(String, Map<String, Object?>)? _functionHandler;

  // Set the function handler (will be called from provider)
  void setFunctionHandler(Function(String, Map<String, Object?>)? handler) {
    _functionHandler = handler;
    debugPrint(
      '🔗 Function handler ${handler != null ? 'connected' : 'disconnected'}',
    );
  }

  // Central function call handler
  Map<String, Object?> handleFunctionCall(
    String functionName,
    Map<String, Object?> arguments,
  ) {
    debugPrint('🔧 Function call: $functionName with arguments: $arguments');

    if (_functionHandler == null) {
      return handleError('Function handler not initialized');
    }

    try {
      final result = _functionHandler!(functionName, arguments);
      if (result != null) {
        debugPrint('✅ Function result: $result');
        return Map<String, Object?>.from(result);
      } else {
        return handleError('Function returned null result');
      }
    } catch (e) {
      debugPrint('❌ Function execution error: $e');
      return handleError('Function execution failed: $e');
    }
  }

  // Handle errors
  Map<String, Object?> handleError(String message) {
    return {'success': false, 'error': true, 'message': message};
  }

  // Task creation function declaration
  FunctionDeclaration get createTaskFuncDecl => FunctionDeclaration(
    'create_task',
    'Create a new task with title, description, and scheduled time.',
    parameters: {
      'title': Schema.string(description: 'The title of the task'),
      'description': Schema.string(
        description: 'Detailed description of the task',
      ),
      'scheduled_time': Schema.string(
        description: 'When the task should be completed (ISO 8601 format)',
      ),
      'priority': Schema.string(
        description: 'Task priority: low, medium, or high',
      ),
    },
  );

  // Task update function declaration
  FunctionDeclaration get updateTaskFuncDecl => FunctionDeclaration(
    'update_task',
    'Update an existing task by ID or Task Number.',
    parameters: {
      'task_id': Schema.string(
        description: 'The ID of the task to update',
        nullable: true,
      ),
      'task_number': Schema.number(
        description: 'Task number to update (1, 2, 3, etc.)',
        nullable: true,
      ),
      'title': Schema.string(
        description: 'New title of the task',
        nullable: true,
      ),
      'description': Schema.string(
        description: 'New description of the task',
        nullable: true,
      ),
      'scheduled_time': Schema.string(
        description: 'New scheduled time (ISO 8601 format)',
        nullable: true,
      ),
      'status': Schema.string(
        description: 'New status: pending, inProgress, completed, or overdue',
        nullable: true,
      ),
    },
  );

  // Task deletion function declaration
  FunctionDeclaration get deleteTaskFuncDecl => FunctionDeclaration(
    'delete_task',
    'Delete a task by ID or Task Number.',
    parameters: {
      'task_id': Schema.string(
        description: 'The ID of the task to delete',
        nullable: true,
      ),
      'task_number': Schema.number(
        description: 'Task number to delete (1, 2, 3, etc.)',
        nullable: true,
      ),
    },
  );

  FunctionDeclaration get updateUsernameFuncDecl => FunctionDeclaration(
    'update_user_name',
    'Update the username of the user with new name.',
    parameters: {
      'name': Schema.string(description: 'The new name of the user'),
    },
  );

  // All available tools
  List<Tool> get tools => [
    Tool.functionDeclarations([
      createTaskFuncDecl,
      updateTaskFuncDecl,
      deleteTaskFuncDecl,
      updateUsernameFuncDecl,
    ]),
  ];

  // Get specific function declaration by name
  FunctionDeclaration? getFunctionDeclaration(String name) {
    switch (name) {
      case 'create_task':
        return createTaskFuncDecl;
      case 'update_task':
        return updateTaskFuncDecl;
      case 'delete_task':
        return deleteTaskFuncDecl;
      case 'update_user_name':
        return updateUsernameFuncDecl;
      default:
        return null;
    }
  }
}
