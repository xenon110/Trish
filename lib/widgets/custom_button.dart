import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'animations/bouncy_button.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isSecondary ? null : AppTheme.buttonGradient,
          color: isSecondary ? AppTheme.backgroundPeach.withOpacity(0.8) : null,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isSecondary ? [] : [
            BoxShadow(
              color: AppTheme.primaryMaroon.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSecondary ? AppTheme.textDark : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
        ),
      ),
    );
  }
}
