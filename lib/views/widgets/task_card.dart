import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:testy/core/constants/app_colors.dart';
import 'package:testy/core/constants/app_dimensions.dart';
import 'package:testy/models/task.dart';
import 'package:testy/utils/color_utils.dart';
import 'task_detail_sheet.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final int index;

  const TaskCard({super.key, required this.task, required this.index});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: AppDimensions.animationMedium),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation immediately when widget appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: ColorUtils.getGradientColors(
                    widget.task.currentStatus,
                  ),
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                boxShadow: [ColorUtils.getTaskShadow(widget.task)],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLarge,
                  ),
                  onTap: () => _showTaskDetails(),
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.spaceXLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        SizedBox(height: AppDimensions.spaceSmall),
                        _buildDescription(),
                        SizedBox(height: AppDimensions.paddingMedium),
                        _buildTimeChip(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.task.title,
            style: TextStyle(
              fontSize: AppDimensions.fontLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
        SizedBox(width: AppDimensions.spaceSmall),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceSmall,
        vertical: AppDimensions.spaceXSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Text(
        widget.task.currentStatus.name.toUpperCase(),
        style: TextStyle(
          fontSize: AppDimensions.fontSmall - 2,
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.task.description,
      style: TextStyle(
        fontSize: AppDimensions.fontSmall + 2,
        color: AppColors.white70,
        height: 1.4,
      ),
    );
  }

  Widget _buildTimeChip() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMedium,
        vertical: AppDimensions.spaceXSmall + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.spaceMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: AppDimensions.iconSmall,
            color: AppColors.white,
          ),
          SizedBox(width: AppDimensions.spaceXSmall + 2),
          Text(
            DateFormat('MMM dd, HH:mm').format(widget.task.scheduledTime),
            style: TextStyle(
              fontSize: AppDimensions.fontSmall,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TaskDetailSheet(task: widget.task),
    );
  }
}
