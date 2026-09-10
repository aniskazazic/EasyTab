import 'package:flutter/material.dart';

class GenerateReportButton extends StatelessWidget {
  const GenerateReportButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      label: Text(isLoading ? 'Generisanje...' : 'Generiši PDF izvještaj'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF93C5FD),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
