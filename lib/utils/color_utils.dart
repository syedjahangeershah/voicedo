import 'package:flutter/material.dart';
import 'package:testy/core/constants/app_colors.dart';
import 'package:testy/models/task.dart';

class ColorUtils {

  static Color getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppColors.pending;
      case TaskStatus.inProgress:
        return AppColors.inProgress;
      case TaskStatus.completed:
        return AppColors.completed;
      case TaskStatus.overdue:
        return AppColors.overdue;
    }
  }

  static Color getTaskColor(TaskModel task) {
    return getStatusColor(task.currentStatus);
  }

  static List<Color> getGradientColors(TaskStatus status) {
    final baseColor = getStatusColor(status);
    return [
      baseColor.withOpacity(0.8),
      baseColor.withOpacity(0.6),
    ];
  }

  static BoxShadow getTaskShadow(TaskModel task) {
    final color = getTaskColor(task);
    return BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 15,
      offset: Offset(0, 8),
    );
  }
}