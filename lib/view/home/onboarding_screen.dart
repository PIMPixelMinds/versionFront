import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool onLastPage = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onLastPage = (index == 3);
              });
            },
            children: [
              OnboardingPage(
                image: isDarkMode
                    ? "assets/onboarding1-1.png"
                    : "assets/onboarding1.png",
                title: local.onboarding1Title,
                description: local.onboarding1Desc,
              ),
              OnboardingPage(
                image: isDarkMode
                    ? "assets/onboarding2-2.png"
                    : "assets/onboarding2.png",
                title: local.onboarding2Title,
                description: local.onboarding2Desc,
              ),
              OnboardingPage(
                image: isDarkMode
                    ? "assets/onboarding3-3.png"
                    : "assets/onboarding3.png",
                title: local.onboarding3Title,
                description: local.onboarding3Desc,
              ),
              OnboardingPage(
                image: isDarkMode
                    ? "assets/onboarding4-4.png"
                    : "assets/onboarding4.png",
                title: local.onboarding4Title,
                description: local.onboarding4Desc,
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: onLastPage
                ? ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('onboardingCompleted', true);
                      Navigator.pushReplacementNamed(context, '/checkLogin');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(local.getStarted),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => _controller.jumpToPage(3),
                        child: Text(local.skip,
                            style: TextStyle(color: AppColors.primaryBlue)),
                      ),
                      SmoothPageIndicator(
                        controller: _controller,
                        count: 4,
                        effect: WormEffect(
                          activeDotColor: AppColors.primaryBlue,
                          dotColor: theme.hintColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        ),
                        child: Text(local.next,
                            style: TextStyle(color: AppColors.primaryBlue)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(40),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 300),
          const SizedBox(height: 30),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
