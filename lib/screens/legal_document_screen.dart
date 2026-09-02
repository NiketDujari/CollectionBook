import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: SelectableText(
            content,

            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}