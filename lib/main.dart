import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:testy/core/constants/app_colors.dart';
import 'package:testy/services/firebase_service.dart';
import 'providers/task_provider.dart';
import 'providers/gemini_provider.dart';
import 'providers/system_prompt_provider.dart';
import 'providers/gemini_tools_provider.dart';
import 'services/voice_service.dart';
import 'services/gemini_chat_service.dart';
import 'views/screens/app_initializer_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        ChangeNotifierProvider(create: (_) => FirebaseService()),
        ChangeNotifierProvider(create: (_) => VoiceService()),
        ChangeNotifierProvider(create: (_) => GeminiChatService()),

        // Gemini related providers
        ChangeNotifierProvider(create: (_) => SystemPromptProvider()),
        ChangeNotifierProvider(create: (_) => GeminiToolsProvider()),
        ChangeNotifierProvider(create: (_) => GeminiProvider()),

        // Task management provider
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: MaterialApp(
          title: 'Voice Task Manager',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: AppColors.background,
            fontFamily: 'Poppins',
          ),
          home: AppInitializerScreen(),
        ),
      ),
    );
  }
}