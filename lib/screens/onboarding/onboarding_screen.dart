import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glassmorphic_card.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _nicknameController = TextEditingController();

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to GroceryMate',
      description: 'Your smart companion for better grocery shopping',
      emoji: '🛒',
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Smart Shopping Lists',
      description: 'Create and manage multiple shopping carts with ease. Track your budget and never forget an item.',
      emoji: '📝',
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Scan & Save',
      description: 'Quickly scan barcodes and capture receipts with OCR. Add items in seconds!',
      emoji: '📱',
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'Track Your Spending',
      description: 'View your shopping history, analyze spending patterns, and save money.',
      emoji: '💰',
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Organize by Categories',
      description: 'Browse items by category and manage your favorite stores.',
      emoji: '🏷️',
      color: Colors.pink,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToNickname() {
    _pageController.animateToPage(
      _pages.length,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a nickname'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('user_nickname', nickname);

    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF0A0E21), const Color(0xFF1D1F33)]
                : [const Color(0xFFF5F7FA), const Color(0xFFE8EAF6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              if (_currentPage < _pages.length)
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _skipToNickname,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length + 1, // +1 for nickname page
                  itemBuilder: (context, index) {
                    if (index < _pages.length) {
                      return _buildOnboardingPage(_pages[index], index);
                    } else {
                      return _buildNicknamePage();
                    }
                  },
                ),
              ),
              // Page indicator and button
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_currentPage < _pages.length) ...[
                      // Dots indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppTheme.primaryGreen
                                  : Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Next button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _nextPage();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ),
          )
              .animate()
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.3, end: 0, delay: 400.ms),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 600.ms)
              .slideY(begin: 0.3, end: 0, delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildNicknamePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 60,
              color: Colors.white,
            ),
          )
              .animate()
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 48),
          Text(
            'What should we call you?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.3, end: 0, delay: 400.ms),
          const SizedBox(height: 16),
          Text(
            'Enter a nickname to personalize your experience',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 600.ms)
              .slideY(begin: 0.3, end: 0, delay: 600.ms),
          const SizedBox(height: 48),
          GlassmorphicCard(
            child: TextField(
              controller: _nicknameController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              decoration: InputDecoration(
                hintText: 'Your nickname',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
              ),
              onSubmitted: (_) => _completeOnboarding(),
            ),
          )
              .animate()
              .fadeIn(delay: 800.ms)
              .slideY(begin: 0.3, end: 0, delay: 800.ms),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _completeOnboarding();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Start Shopping',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 1000.ms)
              .slideY(begin: 0.3, end: 0, delay: 1000.ms),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String emoji;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
  });
}
