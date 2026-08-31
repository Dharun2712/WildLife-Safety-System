import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

/// ForestGuard - Onboarding Feature Slides (Image 4: Know What's Nearby)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Know What\'s Nearby',
      'desc': 'Stay aware of local wildlife activity. We map safe routes and highlight areas to approach with caution.',
      'badge': 'Deer Activity',
      'icon': Icons.explore_outlined,
      'image': 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=600&q=80',
    },
    {
      'title': 'Real-Time Safety Alerts',
      'desc': 'Receive instant push notifications when danger is detected near your current location.',
      'badge': 'Tiger Alert',
      'icon': Icons.warning_amber_rounded,
      'image': 'https://images.unsplash.com/photo-1561731216-c3a4d99437d5?auto=format&fit=crop&w=600&q=80',
    },
    {
      'title': 'Ranger Support & Emergency SOS',
      'desc': 'Direct connection to patrol units and one-tap emergency SOS broadcast in danger zones.',
      'badge': 'Ranger Active',
      'icon': Icons.security_rounded,
      'image': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=600&q=80',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: const Row(
          children: [
            SizedBox(width: 16),
            Icon(Icons.forest_rounded, color: AppTheme.primary, size: 24),
            SizedBox(width: 8),
            Text('FORESTGUARD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary, letterSpacing: 1)),
          ],
        ),
        leadingWidth: 220,
        actions: [
          TextButton(
            onPressed: () => context.go('/role-select'),
            child: const Text(
              'Skip',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (ctx, i) => _buildSlide(_slides[i]),
              ),
            ),

            // Page Indicator Dots (Image 4)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Bottom CTA Button (Image 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
                    } else {
                      context.go('/role-select');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Artwork Container with Floating Badge & Compass Badge Overlay (Image 4)
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Outer Soft Mint Ring (Image 4)
              Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCEFE6),
                  shape: BoxShape.circle,
                ),
              ),
              // Forest Landscape Artwork Circle (Image 4)
              ClipRRect(
                borderRadius: BorderRadius.circular(110),
                child: Image.network(
                  slide['image'] as String,
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              // Center Compass Icon Badge (Image 4)
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Center(
                  child: Icon(slide['icon'] as IconData, color: AppTheme.primary, size: 28),
                ),
              ),
              // Top-Right Floating Badge (Image 4: Deer Activity)
              Positioned(
                top: 10,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pets_rounded, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        slide['badge'] as String,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Title & Subtitle (Image 4)
          Text(
            slide['title'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide['desc'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
