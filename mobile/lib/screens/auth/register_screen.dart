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

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmPasswordCtl = TextEditingController();
  bool _obscure = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _fullNameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _passwordCtl.dispose();
    _confirmPasswordCtl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and conditions.')),
      );
      return;
    }

    final email = _emailCtl.text.trim();
    final username = email.contains('@') ? email.split('@')[0] : email;

    final success = await ref.read(authProvider.notifier).register(
      username: username,
      email: email,
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
      backgroundColor: const Color(0xFFF4FAFD),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Canopy Header Image with ForestGuard Logo (Image 5)
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?auto=format&fit=crop&w=1200&q=80'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        const Color(0xFFF4FAFD),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  child: const Row(
                    children: [
                      Icon(Icons.forest_rounded, color: AppTheme.primary, size: 24),
                      SizedBox(width: 6),
                      Text(
                        'ForestGuard',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Form Body (Image 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Join the network to protect wildlife and ensure trail safety.',
                      style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),

                    if (auth.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(auth.error!, style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildFieldLabel('Full Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _fullNameCtl,
                      decoration: _inputStyle('Jane Doe', Icons.person_outline_rounded),
                      validator: (v) => v == null || v.isEmpty ? 'Enter your full name' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Email Address'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputStyle('jane@example.com', Icons.mail_outline_rounded),
                      validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Phone Number'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneCtl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputStyle('+1(555) 000-0000', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordCtl,
                      obscureText: _obscure,
                      decoration: _inputStyle('••••••••', Icons.lock_outline_rounded).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.outline),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Confirm Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordCtl,
                      obscureText: _obscure,
                      decoration: _inputStyle('••••••••', Icons.history_rounded),
                      validator: (v) => v != _passwordCtl.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 20),

                    // Terms Checkbox (Image 5)
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                        ),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                              children: [
                                TextSpan(text: 'I agree to the '),
                                TextSpan(text: 'terms and conditions', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                                TextSpan(text: ' and privacy policy.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Create Account Button (Image 5)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          elevation: 2,
                        ),
                        child: auth.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CREATE ACCOUNT',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Already have an account Footer (Image 5)
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/login?role=tourist'),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
                            children: [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(text: 'Log in', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.outlineVariant, fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.outlineVariant, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );
  }
}
