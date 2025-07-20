import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testy/core/constants/app_colors.dart';
import 'package:testy/core/constants/app_dimensions.dart';
import 'package:testy/core/constants/app_strings.dart';
import 'package:testy/providers/gemini_provider.dart';
import 'package:testy/providers/gemini_tools_provider.dart';
import 'package:testy/providers/system_prompt_provider.dart';
import 'package:testy/services/firebase_service.dart';
import 'package:testy/services/gemini_chat_service.dart';
import 'package:testy/views/widgets/floating_chat_widget.dart';
import '../../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/recording_indicator.dart';

class TaskManagerScreen extends StatefulWidget {
  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: Duration(milliseconds: AppDimensions.animationMedium),
      vsync: this,
    );
    _listController = AnimationController(
      duration: Duration(milliseconds: AppDimensions.animationXSlow),
      vsync: this,
    );

    _listController.forward();
  }

  Stream<DocumentSnapshot> _getUserNameStream() {
    final firebaseService = context.read<FirebaseService>();
    final userId = firebaseService.currentUserId;

    if (userId != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots();
    } else {
      // Return empty stream if no user ID
      return Stream.empty();
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.surface, AppColors.accent],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildTasksList()),
                  RecordingIndicator(),
                ],
              ),
              // Floating chat widget positioned above recording indicator
              Positioned(
                left: 0,
                right: 0,
                bottom: 100, // Adjust based on RecordingIndicator height
                child: FloatingChatWidget(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: _getUserNameStream(),
            builder: (context, snapshot) {
              String userName = 'Anonymous'; // Default fallback

              if (snapshot.hasData && snapshot.data?.exists == true) {
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                userName = userData?['name'] ?? 'Anonymous';
              }

              return Text(
                'Hello, $userName!', // Dynamic greeting with live name
                style: TextStyle(
                  fontSize: AppDimensions.fontXXLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              );
            },
          ),
          SizedBox(height: AppDimensions.spaceSmall),
          Text(
            AppStrings.subtitle,
            style: TextStyle(
                fontSize: AppDimensions.fontMedium,
                color: AppColors.white70
            ),
          ),
          SizedBox(height: AppDimensions.spaceMedium),
          _buildModelDropdown(),
          SizedBox(height: AppDimensions.spaceXLarge),
          _buildTaskSummary(),
        ],
      ),
    );
  }

  Widget _buildModelDropdown() {
    return Consumer<GeminiProvider>(
      builder: (context, geminiProvider, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(
              color: AppColors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButton<String>(
            value: geminiProvider.currentModelId,
            isExpanded: true,
            underline: SizedBox.shrink(),
            dropdownColor: AppColors.surface,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.white,
              size: AppDimensions.iconMedium,
            ),
            style: TextStyle(
              color: AppColors.white,
              fontSize: AppDimensions.fontMedium,
              fontWeight: FontWeight.w500,
            ),
            items: geminiProvider.models.map((model) {
              final isSelected = geminiProvider.isModelSelected(model.modelId);
              return DropdownMenuItem<String>(
                value: model.modelId,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingSmall,
                    horizontal: AppDimensions.paddingMedium,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          model.displayName,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.white,
                            fontSize: AppDimensions.fontMedium,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(width: AppDimensions.spaceSmall),
                      if (isSelected)
                        Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: AppColors.white,
                            size: AppDimensions.iconSmall,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: geminiProvider.isInitializing
                ? null
                : (String? newModelId) {
              if (newModelId != null) {
                _switchModel(context, newModelId);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _switchModel(BuildContext context, String modelId) async {
    final geminiProvider = Provider.of<GeminiProvider>(context, listen: false);
    final systemPromptProvider = Provider.of<SystemPromptProvider>(context, listen: false);
    final geminiToolsProvider = Provider.of<GeminiToolsProvider>(context, listen: false);
    final geminiChatService = Provider.of<GeminiChatService>(context, listen: false);

    try {
      await geminiProvider.switchModel(modelId, systemPromptProvider, geminiToolsProvider);

      if (geminiProvider.chatSession != null) {
        geminiChatService.initializeChatSession(geminiProvider.chatSession!, modelId: modelId,);
        geminiChatService.setFunctionHandler(
          geminiToolsProvider.geminiTools.handleFunctionCall,
        );
        debugPrint('🔄 Chat service reinitialized with new model: ${geminiChatService.currentModelId}');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.white,
                  size: AppDimensions.iconSmall,
                ),
                SizedBox(width: AppDimensions.spaceSmall),
                Text(
                  'Model switched successfully',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: AppDimensions.fontMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            margin: EdgeInsets.all(AppDimensions.paddingMedium),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_rounded,
                  color: AppColors.white,
                  size: AppDimensions.iconSmall,
                ),
                SizedBox(width: AppDimensions.spaceSmall),
                Text(
                  'Failed to switch model',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: AppDimensions.fontMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            margin: EdgeInsets.all(AppDimensions.paddingMedium),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildTaskSummary() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.task_alt, color: AppColors.white, size: AppDimensions.iconMedium),
              SizedBox(width: AppDimensions.spaceMedium),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.taskCount(provider.tasks.length),
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: AppDimensions.fontLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppStrings.keepWorking,
                    style: TextStyle(
                        color: AppColors.white70,
                        fontSize: AppDimensions.fontSmall
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTasksList() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isEmpty) {
          return EmptyStateWidget();
        }

        return AnimatedBuilder(
          animation: _listController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - _listController.value)),
              child: Opacity(
                opacity: _listController.value,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
                  itemCount: provider.tasks.length,
                  itemBuilder: (context, index) {
                    return TaskCard(
                      task: provider.tasks[index],
                      index: index,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        return AnimatedBuilder(
          animation: _fabController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: provider.isRecording
                      ? [AppColors.error, Colors.redAccent]
                      : [AppColors.primary, AppColors.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (provider.isRecording ? AppColors.error : AppColors.primary)
                        .withOpacity(0.4),
                    blurRadius: AppDimensions.spaceXLarge,
                    offset: Offset(0, AppDimensions.spaceSmall),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _handleVoiceInput,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: AppDimensions.animationMedium),
                  child: Icon(
                    provider.isRecording ? Icons.stop : Icons.mic,
                    key: ValueKey(provider.isRecording),
                    color: AppColors.white,
                    size: AppDimensions.iconLarge,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleVoiceInput() {
    final provider = context.read<TaskProvider>();

    if (provider.isRecording) {
      provider.processVoiceCommand();
      _fabController.reverse();
    } else {
      provider.startRecording();
      _fabController.forward();
    }
  }
}