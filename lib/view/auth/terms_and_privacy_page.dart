import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';

class TermsAndPrivacyPage extends StatefulWidget {
  final String title;
  final String url;

  const TermsAndPrivacyPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<TermsAndPrivacyPage> createState() => _TermsAndPrivacyPageState();
}

class _TermsAndPrivacyPageState extends State<TermsAndPrivacyPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
  appBar: AppBar(
    title: Text(
      widget.title,
      style: TextStyle(
        fontSize: 18, // 👈 ajustez la taille selon vos préférences
        fontWeight: FontWeight.w500,
      ),
    ),
    backgroundColor: AppColors.primaryBlue,
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  backgroundColor: isDarkMode ? Colors.black : Colors.white,
  body: WebViewWidget(controller: _controller),
);
  }
}