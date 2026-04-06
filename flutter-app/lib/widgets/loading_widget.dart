import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withOpacity(0.1),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
