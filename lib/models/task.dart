enum TaskStatus { pending, inProgress, completed, overdue }

class TaskModel {
  final String id;
  String title;
  String description;
  DateTime scheduledTime;
  TaskStatus status;
  DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledTime,
    this.status = TaskStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Check if task is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(scheduledTime) && status != TaskStatus.completed;
  }

  // Auto-update status based on time
  TaskStatus get currentStatus {
    if (status == TaskStatus.completed) return TaskStatus.completed;
    if (isOverdue) return TaskStatus.overdue;
    return status;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'scheduledTime': scheduledTime.toIso8601String(),
    'status': status.index,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    scheduledTime: DateTime.parse(json['scheduledTime']),
    status: TaskStatus.values[json['status'] ?? 0],
    createdAt: DateTime.parse(json['createdAt']),
  );

  TaskModel copyWith({
    String? title,
    String? description,
    DateTime? scheduledTime,
    TaskStatus? status,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}