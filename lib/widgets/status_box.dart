import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StatusType { success, error }

class StatusBox extends StatelessWidget {
  final StatusType type;
  final String title;
  final String? message;

  const StatusBox({
    super.key,
    required this.type,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = type == StatusType.success;
    final background =
        isSuccess ? AppColors.successBackground : AppColors.errorBackground;
    final textColor = isSuccess ? AppColors.successText : AppColors.errorText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, style: TextStyle(color: textColor)),
          ],
        ],
      ),
    );
  }
}
