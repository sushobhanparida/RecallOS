import 'package:flutter/material.dart';

class StackViewerError extends StatelessWidget {
  final String stackId;

  const StackViewerError({super.key, required this.stackId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded,
                  color: Color(0xFF444444), size: 48),
              const SizedBox(height: 16),
              const Text(
                'Stack not found',
                style: TextStyle(
                  color: Color(0xFFF7F7F7),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This link may have been removed or expired.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
