import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = [
    {
      'icon': '🐾',
      'title': 'Wildlife Detection',
      'desc': 'AI-powered cameras detect wildlife in real-time, keeping you informed about nearby animal activity.',
    },
    {
      'icon': '🚨',
      'title': 'Real-time Safety Alerts',
      'desc': 'Receive instant notifications when you\'re near an active wildlife safety zone. Stay alert, stay safe.',
    },
    {
      'icon': '🛡️',
      'title': 'Ranger Protection',
      'desc': 'Professional forest rangers verify alerts and manage safety zones to keep you protected.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppTheme.forestGreen : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } else {
                      context.go('/role-select');
                    }
                  },
                  child: Text(_currentPage < _pages.length - 1 ? 'Next' : 'Get Started'),
                ),
              ),
            ),
            if (_currentPage < _pages.length - 1)
              TextButton(
                onPressed: () => context.go('/role-select'),
                child: const Text('Skip', style: TextStyle(color: Colors.grey)),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, String> page) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.forestGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(page['icon']!, style: const TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page['title']!,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page['desc']!,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
