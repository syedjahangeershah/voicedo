import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:testy/core/constants/app_colors.dart';
import 'package:testy/core/constants/app_dimensions.dart';
import 'package:testy/core/constants/app_strings.dart';
import 'package:testy/models/task.dart';
import 'package:testy/utils/color_utils.dart';

class TaskDetailSheet extends StatelessWidget {
  final TaskModel task;

  const TaskDetailSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXLarge),
          topRight: Radius.circular(AppDimensions.radiusXLarge),
        ),
      ),
      child: Column(
        children: [
          _buildHandle(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  SizedBox(height: AppDimensions.spaceMedium),
                  _buildDescription(),
                  SizedBox(height: AppDimensions.spaceXXLarge),
                  _buildScheduleInfo(),
                  SizedBox(height: AppDimensions.paddingMedium),
                  _buildStatusInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: AppDimensions.spaceMedium),
      width: 40,
      height: AppDimensions.spaceXSmall,
      decoration: BoxDecoration(
        color: AppColors.white54,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      task.title,
      style: TextStyle(
        fontSize: AppDimensions.fontXLarge,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      task.description,
      style: TextStyle(
        fontSize: AppDimensions.fontMedium,
        color: AppColors.white70,
        height: 1.5,
      ),
    );
  }

  Widget _buildScheduleInfo() {
    final taskColor = ColorUtils.getTaskColor(task);

    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: taskColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: taskColor),
          SizedBox(width: AppDimensions.spaceMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.scheduledTime,
                style: TextStyle(
                  fontSize: AppDimensions.fontSmall,
                  color: AppColors.white54,
                ),
              ),
              Text(
                DateFormat('EEEE, MMM dd, yyyy at HH:mm').format(task.scheduledTime),
                style: TextStyle(
                  fontSize: AppDimensions.fontMedium,
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    final taskColor = ColorUtils.getTaskColor(task);

    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: taskColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(), color: taskColor),
          SizedBox(width: AppDimensions.spaceMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.status,
                style: TextStyle(
                  fontSize: AppDimensions.fontSmall,
                  color: AppColors.white54,
                ),
              ),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: AppDimensions.fontMedium,
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (task.currentStatus) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.overdue:
        return Icons.warning;
    }
  }

  String _getStatusText() {
    switch (task.currentStatus) {
      case TaskStatus.pending:
        return AppStrings.pending;
      case TaskStatus.inProgress:
        return AppStrings.inProgress;
      case TaskStatus.completed:
        return AppStrings.completed;
      case TaskStatus.overdue:
        return AppStrings.overdue;
    }
  }
}