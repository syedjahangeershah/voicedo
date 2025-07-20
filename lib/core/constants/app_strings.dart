class AppStrings {
  // App
  static const String appTitle = 'Voice Task Manager';

  // Greetings
  static const String greeting = 'Hello, Jahangeer!';
  static const String subtitle = 'Let\'s manage your tasks';

  // Task Management
  static const String noTasks = 'No tasks yet';
  static const String addFirstTask = 'Tap the microphone to add your first task';
  static const String keepWorking = 'Keep up the great work!';

  // Voice Recording
  static const String listening = 'Listening...';
  static const String processing = 'Processing command...';
  static const String taskProcessed = 'Task processed successfully!';

  // Actions
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';
  static const String save = 'Save';

  // Dialogs
  static const String editTask = 'Edit Task';
  static const String deleteTask = 'Delete Task';
  static const String editPlaceholder = 'Edit functionality would be implemented here';

  // Status
  static const String pending = 'Pending';
  static const String inProgress = 'In Progress';
  static const String completed = 'Completed';
  static const String overdue = 'Overdue';

  // Time
  static const String scheduledTime = 'Scheduled Time';
  static const String status = 'Status';

  static String deleteConfirmation(String taskTitle) =>
      'Are you sure you want to delete "$taskTitle"?';

  static String taskCount(int count) => '$count Tasks';
}