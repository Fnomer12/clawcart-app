import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late final AnimationController _bubbleController;

  bool isLogin = true;
  bool obscure = true;
  bool loading = false;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _friendlyError(Object e) {
    debugPrint('AUTH ERROR TYPE: ${e.runtimeType}');
    debugPrint('AUTH ERROR: $e');

    if (e is FirebaseAuthException) {
      return '${e.code}: ${e.message ?? ''}';
    }

    return e.toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      if (isLogin) {
        await _authService.signInWithEmail(
          email: emailCtrl.text,
          password: passCtrl.text,
        );
        _showMessage('Signed in successfully');
      } else {
        await _authService.registerWithEmail(
          name: nameCtrl.text,
          email: emailCtrl.text,
          password: passCtrl.text,
        );
        _showMessage('Account created successfully');
      }
    } catch (e) {
      _showMessage(_friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => loading = true);

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        _showMessage('Google sign-in successful');
      }
    } catch (e) {
      _showMessage(_friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (emailCtrl.text.trim().isEmpty) {
      _showMessage('Enter your email first');
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(emailCtrl.text);
      _showMessage('Password reset email sent');
    } catch (e) {
      _showMessage(_friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF09090D);
    const panel = Color(0xCC12121A);
    const border = Color(0xFF232331);
    const red = Color(0xFFFF5A52);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bubbleController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _BubbleBackgroundPainter(_bubbleController.value),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bg.withValues(alpha: 0.45),
                  bg.withValues(alpha: 0.88),
                  bg,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          height: 76,
                          width: 76,
                          decoration: BoxDecoration(
                            color: red.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: red.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: red.withValues(alpha: 0.28),
                                blurRadius: 34,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shopping_cart_checkout_rounded,
                            color: red,
                            size: 35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'ClawCart',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: red,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'AI Shopping Assistant',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 13,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: red.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: red,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLogin
                                    ? 'Welcome back'
                                    : 'Create your account',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Tell the assistant what you want — we’ll rank the best options for you.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.66),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _AuthTab(
                            title: 'Sign in',
                            active: isLogin,
                            onTap: () => setState(() => isLogin = true),
                          ),
                        ),
                        Expanded(
                          child: _AuthTab(
                            title: 'Create account',
                            active: !isLogin,
                            onTap: () => setState(() => isLogin = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: border),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!isLogin) ...[
                            TextFormField(
                              controller: nameCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Full name',
                                hint: 'e.g. Adjei Sampson',
                              ),
                              validator: (value) {
                                if (!isLogin &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              label: 'Email',
                              hint: 'you@example.com',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passCtrl,
                            obscureText: obscure,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              label: 'Password',
                              hint: '••••••••',
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => obscure = !obscure),
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your password';
                              }
                              if (value.length < 6) {
                                return 'Minimum 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (isLogin)
                                TextButton(
                                  onPressed:
                                      loading ? null : _forgotPassword,
                                  child: Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.74),
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                isLogin ? 'Secure sign in' : 'Create account',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: red,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      isLogin
                                          ? Icons.lock_open
                                          : Icons.person_add_alt_1,
                                    ),
                              label: Text(
                                isLogin ? 'Sign in' : 'Create account',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: loading ? null : _googleSignIn,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.g_mobiledata, size: 28),
                              label: const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms & Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    Widget? suffix,
  }) {
    const fill = Color(0xDD0D0D14);
    const border = Color(0xFF232331);
    const red = Color(0xFFFF5A52);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: red, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.3),
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _AuthTab({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF5A52);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? red.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? red.withValues(alpha: 0.45) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color:
                  active ? Colors.white : Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleBackgroundPainter extends CustomPainter {
  final double animationValue;

  _BubbleBackgroundPainter(this.animationValue);

  final List<_Bubble> bubbles = List.generate(
    18,
    (index) => _Bubble(
      x: Random(index).nextDouble(),
      y: Random(index + 8).nextDouble(),
      radius: 18 + Random(index + 20).nextDouble() * 58,
      speed: 0.12 + Random(index + 40).nextDouble() * 0.26,
      opacity: 0.05 + Random(index + 60).nextDouble() * 0.16,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final red = const Color(0xFFFF5A52);
    final orange = const Color(0xFFFFA000);
    final purple = const Color(0xFF7C4DFF);

    for (int i = 0; i < bubbles.length; i++) {
      final bubble = bubbles[i];

      final dy =
          ((bubble.y + animationValue * bubble.speed) % 1.2) * size.height -
              80;

      final dx = bubble.x * size.width +
          sin((animationValue * 2 * pi) + i) * 18;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            (i % 3 == 0 ? red : i % 3 == 1 ? orange : purple)
                .withValues(alpha: bubble.opacity),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(dx, dy),
            radius: bubble.radius,
          ),
        );

      canvas.drawCircle(
        Offset(dx, dy),
        bubble.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _Bubble {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double opacity;

  const _Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
  });
}