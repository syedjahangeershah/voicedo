import 'package:firebase_ai/firebase_ai.dart';

class GeminiTools {
  // Function handler for processing function calls
  Function(String, Map<String, Object?>)? _functionHandler;

  // Set the function handler (will be called from provider)
  void setFunctionHandler(Function(String, Map<String, Object?>)? handler) {
    _functionHandler = handler;
    print('🔗 Function handler ${handler != null ? 'connected' : 'disconnected'}');
  }

  // Central function call handler
  Map<String, Object?> handleFunctionCall(
      String functionName,
      Map<String, Object?> arguments,
      ) {
    print('🔧 Function call: $functionName with arguments: $arguments');

    if (_functionHandler == null) {
      return handleError('Function handler not initialized');
    }

    try {
      final result = _functionHandler!(functionName, arguments);
      if (result != null) {
        print('✅ Function result: $result');
        return Map<String, Object?>.from(result);
      } else {
        return handleError('Function returned null result');
      }
    } catch (e) {
      print('❌ Function execution error: $e');
      return handleError('Function execution failed: $e');
    }
  }

  // Handle errors
  Map<String, Object?> handleError(String message) {
    return {
      'success': false,
      'error': true,
      'message': message,
    };
  }
  // Task creation function declaration
  FunctionDeclaration get createTaskFuncDecl => FunctionDeclaration(
    'create_task',
    'Create a new task with title, description, and scheduled time.',
    parameters: {
      'title': Schema.string(description: 'The title of the task'),
      'description': Schema.string(description: 'Detailed description of the task'),
      'scheduled_time': Schema.string(description: 'When the task should be completed (ISO 8601 format)'),
      'priority': Schema.string(description: 'Task priority: low, medium, or high'),
    },
  );

  // Task update function declaration
  FunctionDeclaration get updateTaskFuncDecl => FunctionDeclaration(
    'update_task',
    'Update an existing task by ID.',
    parameters: {
      'task_id': Schema.string(description: 'The ID of the task to update'),
      'title': Schema.string(description: 'New title of the task', nullable: true),
      'description': Schema.string(description: 'New description of the task', nullable: true),
      'scheduled_time': Schema.string(description: 'New scheduled time (ISO 8601 format)', nullable: true),
      'status': Schema.string(description: 'New status: pending, inProgress, completed, or overdue', nullable: true),
    },
  );

  // Task deletion function declaration
  FunctionDeclaration get deleteTaskFuncDecl => FunctionDeclaration(
    'delete_task',
    'Delete a task by ID.',
    parameters: {
      'task_id': Schema.string(description: 'The ID of the task to delete'),
    },
  );

  // All available tools
  List<Tool> get tools => [
    Tool.functionDeclarations([
      createTaskFuncDecl,
      updateTaskFuncDecl,
      deleteTaskFuncDecl,
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
      default:
        return null;
    }
  }

  // Get all function names
  List<String> get functionNames => [
    'create_task',
    'update_task',
    'delete_task',
    'list_tasks',
    'search_tasks',
    'complete_task',
    'get_task_stats',
    'schedule_reminder',
  ];

}