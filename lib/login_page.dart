flutter --versionimport 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:ims_pos/helpers/user_manager.dart';
import 'package:ims_pos/theme.dart';
import 'dart:ui';
import 'sale_screen_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;

  // Animation for top-right message
  late OverlayEntry _overlayEntry;

  void _showTopRightMessage(String message) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 40,
        right: 20,
        child: _AnimatedMessage(message: message),
      ),
    );

    Overlay.of(context).insert(_overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      _overlayEntry.remove();
    });
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: orangeColor),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('https://www.laravel-imsonline.online/api/v1/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      // Always show only the message from API
      final message = data['message'] ?? 'Login failed';

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'];
        final user = data['data']['user'];
        await UserManager.saveUser(user, token);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SaleScreenPage()),
        );
      } else {
        _showTopRightMessage(message);
      }
    } catch (e) {
      _showTopRightMessage('Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final formWidth = screenWidth > 450 ? 400.0 : screenWidth * 0.9;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset('assets/images/angkor_wat.jpg', fit: BoxFit.cover),

          // Blur + overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // Centered Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: formWidth,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 70,
                          color: orangeColor,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: orangeColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Login to continue',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 32),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration(
                            'Email',
                            Icons.email_outlined,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Email is required';
                            // Simple email regex
                            final emailRegex = RegExp(
                              r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
                            );
                            if (!emailRegex.hasMatch(v.trim()))
                              return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          decoration: _inputDecoration('Password', Icons.lock)
                              .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: orangeColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _hidePassword = !_hidePassword;
                                    });
                                  },
                                ),
                              ),
                          validator: (v) =>
                              v!.isEmpty ? 'Password is required' : null,
                        ),
                        const SizedBox(height: 28),

                        // Login Button
                        _loading
                            ? const CircularProgressIndicator(
                                color: orangeColor,
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: orangeColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated message widget
class _AnimatedMessage extends StatefulWidget {
  final String message;
  const _AnimatedMessage({required this.message});

  @override
  State<_AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<_AnimatedMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    // Fade out after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: Colors.redAccent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            widget.message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
