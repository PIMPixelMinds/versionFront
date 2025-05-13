import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class TermsAndPrivacyPage extends StatefulWidget {
  final String titleKey;

  const TermsAndPrivacyPage({super.key, required this.titleKey});

  @override
  State<TermsAndPrivacyPage> createState() => _TermsAndPrivacyPageState();
}

class _TermsAndPrivacyPageState extends State<TermsAndPrivacyPage> {
  late final WebViewController _controller;
  bool _isHtmlLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isHtmlLoaded) {
      _loadLocalizedHtml();
      _isHtmlLoaded = true;
    }
    // Update WebView theme when dependencies (e.g., theme) change
    _updateWebViewTheme();
  }

  Future<void> _loadLocalizedHtml() async {
    final locale = AppLocalizations.of(context)?.localeName ?? 'en';
    String htmlPath;

    if (widget.titleKey == 'termsAndConditions') {
      htmlPath = locale == 'fr' ? 'assets/html/terms_fr.html' : 'assets/html/terms_en.html';
    } else {
      htmlPath = locale == 'fr' ? 'assets/html/privacy_fr.html' : 'assets/html/privacy_en.html';
    }

    try {
      final htmlContent = await rootBundle.loadString(htmlPath);
      _controller.loadHtmlString(htmlContent);
      // Apply theme after content is loaded
      await _updateWebViewTheme();
    } catch (e) {
      _controller.loadHtmlString('''
        <!DOCTYPE html>
        <html>
        <body>
          <h1>Error</h1>
          <p>Could not load content: $e</p>
        </body>
        </html>
      ''');
    }
  }

  Future<void> _updateWebViewTheme() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Inject JavaScript to toggle .dark class on <body>
    await _controller.runJavaScript('''
      document.body.classList.toggle('dark', $isDarkMode);
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final title = widget.titleKey == 'termsAndConditions'
        ? localizations.termsAndConditions
        : localizations.privacyPolicy;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.white),
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: WebViewWidget(controller: _controller),
    );
  }
}