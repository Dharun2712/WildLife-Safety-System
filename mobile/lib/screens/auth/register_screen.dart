import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _fullNameCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  bool _obscure = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _usernameCtl.dispose();
    _emailCtl.dispose();
    _fullNameCtl.dispose();
    _passwordCtl.dispose();
    _phoneCtl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
      username: _usernameCtl.text.trim(),
      email: _emailCtl.text.trim(),
      password: _passwordCtl.text,
      fullName: _fullNameCtl.text.trim(),
      phone: _phoneCtl.text.trim().isNotEmpty ? _phoneCtl.text.trim() : null,
    );

    if (!mounted) return;
    if (success) {
      context.go('/tourist');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        color: const Color(0xFFF8FAF9),
        child: Column(
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 28,
              ),
              decoration: BoxDecoration(
                gradient: AppTheme.emeraldGlow,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: AppTheme.glowShadow(AppTheme.forestGreen, intensity: 0.15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                    onPressed: () => context.go('/login?role=tourist'),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🏕️', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 10),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Join ForestGuard as a tourist',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final slide = Tween<double>(begin: 40, end: 0).animate(
                      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
                    );
                    final fade = Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
                    );
                    return Opacity(
                      opacity: fade.value,
                      child: Transform.translate(
                        offset: Offset(0, slide.value),
                        child: child,
                      ),
                    );
                  },
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error
                        if (auth.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerRed.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.error_outline, color: AppTheme.dangerRed, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(auth.error!, style: const TextStyle(color: AppTheme.dangerRed, fontSize: 13, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        _fieldLabel('Full Name'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _fullNameCtl,
                          decoration: InputDecoration(
                            hintText: 'Enter your full name',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.forestGreen.withValues(alpha: 0.6)),
                          ),
                          validator: (v) => v == null || v.length < 2 ? 'Enter your full name' : null,
                        ),
                        const SizedBox(height: 16),

                        _fieldLabel('Username'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usernameCtl,
                          decoration: InputDecoration(
                            hintText: 'Choose a username',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.forestGreen.withValues(alpha: 0.6)),
                          ),
                          validator: (v) => v == null || v.length < 3 ? 'Min 3 characters' : null,
                        ),
                        const SizedBox(height: 16),

                        _fieldLabel('Email'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'your@email.com',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.forestGreen.withValues(alpha: 0.6)),
                          ),
                          validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 16),

                        _fieldLabel('Phone (optional)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneCtl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '+91 XXXXXXXXXX',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.forestGreen.withValues(alpha: 0.6)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _fieldLabel('Password'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordCtl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: 'Create a strong password',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: AppTheme.forestGreen.withValues(alpha: 0.6)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 28),

                        // Register button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.emeraldGlow,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: auth.isLoading
                                  ? null
                                  : AppTheme.glowShadow(AppTheme.forestGreen, intensity: 0.2),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: auth.isLoading ? null : _register,
                                child: Center(
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                        )
                                      : const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/login?role=tourist'),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                children: const [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                      color: AppTheme.forestGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }
}
