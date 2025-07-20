import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testy/core/constants/app_colors.dart';
import 'package:testy/core/constants/app_dimensions.dart';
import 'package:testy/core/constants/app_strings.dart';
import 'package:testy/providers/task_provider.dart';

class RecordingIndicator extends StatelessWidget {
  const RecordingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (!provider.isRecording && !provider.isProcessing) {
          return SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: Duration(milliseconds: AppDimensions.animationMedium),
          height: provider.isRecording || provider.isProcessing ? 89 : 0,
          child: Container(
            margin: EdgeInsets.all(AppDimensions.paddingMedium),
            padding: EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: provider.isRecording
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.inProgress.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),

            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: AppDimensions.animationMedium),
                  child: Icon(
                    provider.isRecording ? Icons.mic : Icons.psychology,
                    color: provider.isRecording ? AppColors.error : AppColors.inProgress,
                    size: AppDimensions.iconMedium,
                  ),
                ),
                SizedBox(width: AppDimensions.spaceMedium),
                Expanded(
                  child: Text(
                    provider.isRecording ? AppStrings.listening : AppStrings.processing,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: AppDimensions.fontMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (provider.isProcessing)
                  SizedBox(
                    width: AppDimensions.spaceXLarge,
                    height: AppDimensions.spaceXLarge,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.inProgress),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}