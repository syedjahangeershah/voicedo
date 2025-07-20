import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testy/core/constants/app_colors.dart';
import 'package:testy/core/constants/app_dimensions.dart';
import 'package:testy/models/chat_message.dart';
import 'package:testy/providers/task_provider.dart';
import '../../services/gemini_chat_service.dart';

class FloatingChatWidget extends StatefulWidget {
  const FloatingChatWidget({super.key});

  @override
  State<FloatingChatWidget> createState() => _FloatingChatWidgetState();
}

class _FloatingChatWidgetState extends State<FloatingChatWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isMinimized = true; // Add this new state variable
  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;

  void _toggleExpansion() {
    if (_isMinimized) {
      // First click - expand from circular to chat box
      setState(() {
        _isMinimized = false;
      });
    } else {
      // Second click - toggle fullscreen
      setState(() {
        _isExpanded = !_isExpanded;
        if (_isExpanded) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  void _minimizeChat() {
    setState(() {
      _isMinimized = true;
      _isExpanded = false;
      _animationController.reverse();
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _sizeAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // Show circular button when minimized
        if (_isMinimized) {
          return Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
              ),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.95),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleExpansion,
                    borderRadius: BorderRadius.circular(28),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.white,
                      size: AppDimensions.iconMedium,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        // Show expanded chat
        return AnimatedBuilder(
          animation: _sizeAnimation,
          builder: (context, child) {
            final screenHeight = MediaQuery.of(context).size.height;
            final chatHeight = _isExpanded
                ? screenHeight * _sizeAnimation.value
                : 250.0;

            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: chatHeight,
              margin: EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                border: Border.all(color: AppColors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildChatHeader(),
                  Expanded(child: _buildChatContent()),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatHeader() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusLarge),
              topRight: Radius.circular(AppDimensions.radiusLarge),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: AppColors.white,
                size: AppDimensions.iconSmall,
              ),
              SizedBox(width: AppDimensions.spaceSmall),
              Expanded(
                child: Text(
                  'Voice Chat',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: AppDimensions.fontMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  provider.clearMessages();
                },
                icon: Icon(
                  Icons.clear_all,
                  color: AppColors.white,
                  size: AppDimensions.iconSmall,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: _toggleExpansion,
                icon: Icon(
                  _isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: AppColors.white,
                  size: AppDimensions.iconSmall,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: _minimizeChat,
                icon: Icon(
                  Icons.minimize,
                  color: AppColors.white,
                  size: AppDimensions.iconSmall,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatContent() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.messages.isEmpty) {
          return Center(
            child: Text(
              'Voice messages will appear here',
              style: TextStyle(
                color: AppColors.white70,
                fontSize: AppDimensions.fontSmall,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(AppDimensions.paddingMedium),
          itemCount: provider.messages.length,
          itemBuilder: (context, index) {
            final message = provider.messages[index];
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppDimensions.spaceSmall),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.smart_toy, color: AppColors.white, size: 14),
            ),
            SizedBox(width: AppDimensions.spaceSmall),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : AppColors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: AppDimensions.fontSmall,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: AppDimensions.spaceSmall),
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person, color: AppColors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}
