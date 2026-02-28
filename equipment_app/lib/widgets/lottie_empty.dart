// lib/widgets/lottie_empty.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/app_theme.dart';

/// หน้าว่าง พร้อม Lottie animation
class LottieEmpty extends StatelessWidget {
  final String message;
  final String? subMessage;
  const LottieEmpty({
    super.key,
    required this.message,
    this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (subMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              subMessage!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading พร้อม Lottie animation
class LottieLoading extends StatelessWidget {
  const LottieLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animations/loading.json',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

/// Placeholder รูปครุภัณฑ์
class EquipmentPlaceholder extends StatelessWidget {
  final double size;
  final Color color;
  const EquipmentPlaceholder({
    super.key,
    this.size = 56,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'assets/images/placeholder.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.devices,
            color: color,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// Success animation overlay
class LottieSuccess extends StatelessWidget {
  const LottieSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/success.json',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
      repeat: false,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.check_circle,
        color: AppColors.secondary,
        size: 60,
      ),
    );
  }
}
