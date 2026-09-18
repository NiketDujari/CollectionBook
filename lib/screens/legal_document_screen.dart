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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? Colors.black : const Color(0xFF182449),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: SelectableText(
            content,

            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF2A2622),
            ),
          ),
        ),
      ),
    );
  }
}