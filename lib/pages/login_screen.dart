// File: lib/pages/login_screen.dart

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart'; // Import halaman sign up
import '../main.dart'; // Import untuk AppColorsLight/supabase

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // STATE RIVE DAN VISIBILITY
  bool _isPasswordVisible = false;
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  StateMachineController? controller;
  SMIBool? lookOnEmail;
  SMINumber? followOnEmail;
  SMIBool? lookOnPassword;
  SMIBool? peekOnPassword;
  SMITrigger? triggerSuccess;
  SMITrigger? triggerFail;
  // -------------------------

  bool _isLoading = false;

  @override
  void initState() {
    // RIVE LISTENERS
    emailFocusNode.addListener(() {
      lookOnEmail?.change(emailFocusNode.hasFocus);
    });
    passwordFocusNode.addListener(() {
      lookOnPassword?.change(passwordFocusNode.hasFocus);
      if (!passwordFocusNode.hasFocus) {
        peekOnPassword?.change(false);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    _emailController.dispose();
    emailFocusNode.dispose();
    _passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
    peekOnPassword?.change(_isPasswordVisible);
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan Password harus diisi.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await AuthService().signInUser(
      email: email,
      password: password,
      context: context,
    );

    // Logika RIVE (Dipindahkan ke Auth Service)
    final user = supabase.auth.currentUser;

    if (user != null) {
      triggerSuccess?.fire();
    } else {
      triggerFail?.fire();
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final formWidth = screenSize.width > 600 ? 400.0 : screenSize.width * 0.85;

    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text('Hafid Belajar'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
          child: Container(
            width: formWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. RIVE ANIMATION
                SizedBox(
                  height: 250,
                  width: 250,
                  child: RiveAnimation.asset(
                    "assets/animation/auth_teddy.riv",
                    fit: BoxFit.fitHeight,
                    onInit: (artboard) {
                      controller = StateMachineController.fromArtboard(
                        artboard,
                        "Login Machine",
                      );

                      if (controller == null) return;
                      artboard.addController(controller!);

                      lookOnEmail = controller?.getBoolInput("isFocus");
                      followOnEmail = controller?.getNumberInput("numLook");
                      lookOnPassword =
                          controller?.getBoolInput("isPrivateField");
                      peekOnPassword =
                          controller?.getBoolInput("isPrivateFieldShow");
                      triggerSuccess =
                          controller?.getTriggerInput("successTrigger");
                      triggerFail = controller?.getTriggerInput("failTrigger");
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 2. LOGIN FORM
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selamat Datang!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Input Email
                      TextField(
                        focusNode: emailFocusNode,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        onChanged: (value) {
                          followOnEmail?.change(value.length * 1.5);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Input Password
                      TextField(
                        focusNode: passwordFocusNode,
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // --- TOMBOL DAFTAR YANG HILANG ---
                      TextButton(
                        onPressed: () {
                          emailFocusNode.unfocus();
                          passwordFocusNode.unfocus();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUpScreen()),
                          );
                        },
                        child: const Text('Belum punya akun? Daftar di sini'),
                      ),
                      // -------------------------------
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
