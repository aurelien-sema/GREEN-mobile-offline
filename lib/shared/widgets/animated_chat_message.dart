import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class AnimatedChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? imageUrl;
  final int index;

  const AnimatedChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.imageUrl,
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
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
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
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
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
}
