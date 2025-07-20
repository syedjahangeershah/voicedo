import 'package:flutter/material.dart';
import 'package:testy/core/constants/app_colors.dart';
import 'package:testy/core/constants/app_dimensions.dart';
import 'package:testy/core/constants/app_strings.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.voice_chat,
              size: AppDimensions.iconXLarge,
              color: AppColors.white54,
            ),
          ),
          SizedBox(height: AppDimensions.spaceXXLarge),
          Text(
            AppStrings.noTasks,
            style: TextStyle(
              fontSize: AppDimensions.fontXLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: AppDimensions.spaceSmall),
          Text(
            AppStrings.addFirstTask,
            style: TextStyle(
              fontSize: AppDimensions.fontMedium,
              color: AppColors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}