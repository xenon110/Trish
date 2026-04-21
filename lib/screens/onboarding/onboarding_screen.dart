import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Find\nmeaningful\nconnections',
      'subtitle': 'Join a community built on intent,\nwarmth, and genuine human\nconnection.',
      'image': AppConstants.placeholderCouple,
    },
    {
      'title': 'Connect\nbeyond looks',
      'subtitle': 'Discover meaningful connections\nbased on shared interests and\nvalues.',
      'image': AppConstants.placeholderSuitMan,
    },
    {
      'title': 'Express through\nreal moments',
      'subtitle': 'Connect beyond words. Share\nsnippets of your day and find people\nwho resonate with your authenticity.',
      'image': AppConstants.placeholderCoffeeCamera,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMaroon),
                              onPressed: () {
                                if (_currentPage > 0) {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              child: const Text('Skip', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 500, // Reasonable base height
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (int page) {
                              setState(() {
                                _currentPage = page;
                              });
                            },
                            itemCount: _pages.length,
                            itemBuilder: (context, index) {
                              return _buildPage(_pages[index]);
                            },
                          ),
                        ),
                      ),
                      _buildNavigationArea(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, String> page) {
    final bool isAsset = page['image']!.startsWith('assets/');
    final bool isThirdPage = page['title']!.contains('Express');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(44),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryMaroon.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
                image: DecorationImage(
                  image: isAsset 
                      ? AssetImage(page['image']!) as ImageProvider 
                      : NetworkImage(page['image']!),
                  fit: isThirdPage ? BoxFit.cover : BoxFit.cover, // Keeping cover but adjusting container if needed
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  page['title']!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 38,
                        height: 1.1,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    page['subtitle']!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textLight,
                          height: 1.6,
                          fontSize: 17,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationArea() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildDot(index),
            ),
          ),
          const SizedBox(height: 30),
          CustomButton(
            text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
            onPressed: () {
              if (_currentPage == _pages.length - 1) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive ? AppTheme.primaryMaroon : AppTheme.primaryMaroon.withOpacity(0.2),
      ),
    );
  }
}
