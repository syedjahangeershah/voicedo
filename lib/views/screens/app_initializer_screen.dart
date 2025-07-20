import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testy/services/firebase_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/gemini_provider.dart';
import '../../providers/system_prompt_provider.dart';
import '../../providers/gemini_tools_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/gemini_chat_service.dart';
import '../../services/voice_service.dart';
import 'task_manager_screen.dart';

class AppInitializerScreen extends StatefulWidget {
  const AppInitializerScreen({super.key});

  @override
  State<AppInitializerScreen> createState() => _AppInitializerScreenState();
}

class _AppInitializerScreenState extends State<AppInitializerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: AppDimensions.animationXSlow),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(Duration(milliseconds: 500)); // Minimum splash time

      final geminiProvider = context.read<GeminiProvider>();
      final systemPromptProvider = context.read<SystemPromptProvider>();
      final geminiToolsProvider = context.read<GeminiToolsProvider>();
      final taskProvider = context.read<TaskProvider>();
      final voiceService = context.read<VoiceService>();
      final geminiChatService = context.read<GeminiChatService>();
      final firebaseService = context.read<FirebaseService>();

      // Initialize Gemini components
      await geminiProvider.initializeAll(
        systemPromptProvider,
        geminiToolsProvider,
      );

      final firebaseInitialized = await firebaseService.initialize();

      if (!firebaseInitialized) {
        throw Exception('Firebase initialization failed!');
      }

      // Connect TaskProvider to GeminiTools for function handling
      geminiToolsProvider.setTaskProvider(taskProvider);

      // Initialize chat session
      if (geminiProvider.chatSession != null) {
        geminiChatService.initializeChatSession(geminiProvider.chatSession!);
        geminiChatService.setFunctionHandler(
          geminiToolsProvider.geminiTools.handleFunctionCall,
        );
      }

      // Initialize voice service
      await voiceService.initialize();

      taskProvider.setServices(
        voiceService,
        geminiChatService,
        firebaseService,
      );

      await Future.delayed(const Duration(seconds: 2));
      _navigateToTaskManager();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _navigateToTaskManager() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TaskManagerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: AppDimensions.animationSlow),
      ),
    );
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _hasError ? _buildErrorView() : _buildLoadingView(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo/Icon
          Container(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.task_alt,
              size: AppDimensions.iconXLarge + 20,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: AppDimensions.spaceXXLarge),

          // App Title
          Text(
            AppStrings.appTitle,
            style: TextStyle(
              fontSize: AppDimensions.fontXXLarge + 4,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: AppDimensions.spaceSmall),

          Text(
            'Powered by Gemini AI',
            style: TextStyle(
              fontSize: AppDimensions.fontMedium,
              color: AppColors.white70,
            ),
          ),
          SizedBox(height: AppDimensions.spaceXXLarge * 2),

          // Loading Indicator
          Consumer<GeminiProvider>(
            builder: (context, geminiProvider, child) {
              return Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: AppDimensions.paddingMedium),
                  Text(
                    _getLoadingMessage(geminiProvider),
                    style: TextStyle(
                      fontSize: AppDimensions.fontMedium,
                      color: AppColors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            Container(
              padding: EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.error_outline,
                size: AppDimensions.iconXLarge,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppDimensions.spaceXXLarge),

            // Error Title
            Text(
              'Initialization Failed',
              style: TextStyle(
                fontSize: AppDimensions.fontXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: AppDimensions.spaceMedium),

            // Error Message
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: TextStyle(
                fontSize: AppDimensions.fontMedium,
                color: AppColors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spaceXXLarge),

            // Retry Button
            ElevatedButton(
              onPressed: _retryInitialization,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge * 2,
                  vertical: AppDimensions.paddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: AppDimensions.iconMedium),
                  SizedBox(width: AppDimensions.spaceSmall),
                  Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: AppDimensions.fontMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLoadingMessage(GeminiProvider geminiProvider) {
    if (geminiProvider.firebaseApp == null) {
      return 'Initializing Firebase...';
    } else if (geminiProvider.geminiModel == null) {
      return 'Setting up Gemini AI...';
    } else if (geminiProvider.chatSession == null) {
      return 'Starting chat session...';
    } else {
      return 'All SDKs initialized! Almost ready...';
    }
  }
}
