import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class AnimatedChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? imageUrl; // For message attachment (image sent by user)
  final String? avatarUrl; // For user profile photo
  final int index;

  const AnimatedChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.imageUrl,
    this.avatarUrl,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bot Avatar (Left)
            if (!isUser) _buildAvatar(isDarkMode),

            Flexible(
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                   // Image Attachment
                  if (imageUrl != null)
                    Container(
                      margin: const EdgeInsets.only(
                        bottom: AppConstants.paddingSmall,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium,
                        ),
                        child: Image.network(
                          imageUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: isDarkMode
                                  ? AppColors.darkTertiary
                                  : AppColors.lightTertiary,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    ),
                  
                  // Text Message Bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.70,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: AppConstants.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? (isDarkMode
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary)
                          : (isDarkMode
                                ? AppColors.darkTertiary
                                : AppColors.lightTertiary),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppConstants.radiusMedium),
                        topRight: Radius.circular(AppConstants.radiusMedium),
                        bottomLeft: Radius.circular(
                          isUser ? AppConstants.radiusMedium : 4,
                        ),
                        bottomRight: Radius.circular(
                          isUser ? 4 : AppConstants.radiusMedium,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : (isDarkMode
                                  ? AppColors.darkOnBackground
                                  : AppColors.lightOnBackground),
                        fontSize: AppConstants.fontSizeRegular,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // User Avatar (Right)
            if (isUser) _buildAvatar(isDarkMode),
          ],
        ),
      ),
    )
    .animate(delay: Duration(milliseconds: index * 50))
    .slideY(
      begin: 0.5,
      end: 0,
      curve: Curves.easeOut,
      duration: AppConstants.animationNormal,
    )
    .fadeIn(duration: AppConstants.animationNormal);
  }

  Widget _buildAvatar(bool isDarkMode) {
    if (!isUser) {
      // Bot Avatar
      return Container(
        margin: const EdgeInsets.only(right: 8),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: const DecorationImage(
            image: AssetImage('assets/images/logo.png'),
            fit: BoxFit.cover,
          ),
          border: Border.all(
             color: isDarkMode ? Colors.white24 : Colors.black12,
             width: 1,
          ),
        ),
      );
    } 
    
    // User Avatar
    return Container(
      margin: const EdgeInsets.only(left: 8),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(
             color: isDarkMode ? Colors.white24 : Colors.black12,
             width: 1,
        ),
        image: avatarUrl != null
              ? DecorationImage(
                  image: FileImage(File(avatarUrl!)),
                  fit: BoxFit.cover,
                )
              : null,
      ),
      child: avatarUrl == null
          ? Icon(
              Icons.person, 
              size: 20, 
              color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
            )
          : null,
    );
  }
}
