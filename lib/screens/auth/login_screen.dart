import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../services/auth_service.dart';
import '../../utils/app_navigator.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../admin/admin_dashboard_screen.dart';
import '../company/company_dashboard_screen.dart';
import '../user/user_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final error = await _authService.signIn(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    // Get user role (only one call instead of two)
    final role = await _authService.getUserRole();
    if (!mounted) return;

    Widget destination;
    switch (role) {
      case AppConstants.roleAdmin:
        destination = const AdminDashboardScreen();
        break;
      case AppConstants.roleCompany:
        destination = const CompanyDashboardScreen();
        break;
      default:
        destination = const UserHomeScreen();
        break;
    }

    // Refresh token in background after navigation
    _authService.refreshIdToken();

    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _socialSignIn(String provider) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    String? error;
    if (provider == 'Google') {
      error = await _authService.signInWithGoogle();
    } else if (provider == 'GitHub') {
      error = await _authService.signInWithGitHub();
    }

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _loading = false;
        _errorMessage = error;
      });
      return;
    }

    // Get user role and redirect (same as email/password sign-in)
    final role = await _authService.getUserRole();
    if (!mounted) return;
    setState(() => _loading = false);

    Widget destination;
    switch (role) {
      case AppConstants.roleAdmin:
        destination = const AdminDashboardScreen();
        break;
      case AppConstants.roleCompany:
        destination = const CompanyDashboardScreen();
        break;
      default:
        destination = const UserHomeScreen();
        break;
    }

    // Refresh token in background after navigation
    _authService.refreshIdToken();

    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your account email and we will send a reset link.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              if (ctrl.text.trim().isEmpty) return;
              await _authService.sendPasswordReset(ctrl.text.trim());
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('Reset link sent. Check your inbox.')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ScrollConfiguration(
                      behavior: const _NoScrollbarBehavior(),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  const _AuthHeader(
                                    title: AppConstants.appName,
                                    subtitle: 'Internship Platform',
                                    icon: FontAwesomeIcons.briefcase,
                                  ),
                                  const SizedBox(height: 12),
                                  Card(
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.all(22),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Welcome back',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Sign in to your ${AppConstants.appName} account',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            const SizedBox(height: 18),
                                            Text(
                                              'Email address',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge,
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _emailController,
                                              focusNode: _emailFocus,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              cursorColor: AppTheme.primary,
                                              textInputAction:
                                                  TextInputAction.next,
                                              onFieldSubmitted: (_) =>
                                                  _passwordFocus.requestFocus(),
                                              decoration: const InputDecoration(
                                                hintText: 'you@example.com',
                                                prefixIcon: Icon(
                                                  Icons.email_outlined,
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return AppConstants
                                                      .valEmailRequired;
                                                }
                                                if (!AppConstants.emailRegex
                                                    .hasMatch(value.trim())) {
                                                  return AppConstants.valEmail;
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              'Password',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge,
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _passwordController,
                                              focusNode: _passwordFocus,
                                              obscureText: _obscurePassword,
                                              cursorColor: AppTheme.primary,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onFieldSubmitted: (_) =>
                                                  _signIn(),
                                              decoration: InputDecoration(
                                                hintText: 'Enter your password',
                                                prefixIcon: const Icon(
                                                  Icons.lock_outline,
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: FaIcon(
                                                    _obscurePassword
                                                        ? FontAwesomeIcons.eye
                                                        : FontAwesomeIcons
                                                            .eyeSlash,
                                                    size: 17,
                                                  ),
                                                  onPressed: () => setState(
                                                    () => _obscurePassword =
                                                        !_obscurePassword,
                                                  ),
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return AppConstants
                                                      .valPasswordRequired;
                                                }
                                                if (value.length <
                                                    AppConstants
                                                        .minPasswordLength) {
                                                  return AppConstants
                                                      .valPasswordLength;
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: () =>
                                                    _showForgotPassword(
                                                        context),
                                                child: const Text(
                                                    'Forgot password?'),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            if (_errorMessage != null) ...[
                                              ErrorBanner(
                                                message: _errorMessage!,
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed:
                                                    _loading ? null : _signIn,
                                                style: ElevatedButton.styleFrom(
                                                  minimumSize: const Size(
                                                    double.infinity,
                                                    48,
                                                  ),
                                                ),
                                                child: _loading
                                                    ? const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          SizedBox(
                                                            height: 18,
                                                            width: 18,
                                                            child:
                                                                CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2,
                                                            ),
                                                          ),
                                                          SizedBox(width: 12),
                                                          Text('Signing in...'),
                                                        ],
                                                      )
                                                    : const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          FaIcon(
                                                            FontAwesomeIcons
                                                                .circleCheck,
                                                            size: 20,
                                                          ),
                                                          SizedBox(width: 12),
                                                          Text('Sign In'),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            _SocialButtons(
                                              onPressed: _loading
                                                  ? null
                                                  : _socialSignIn,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'New to ${AppConstants.appName}? ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen(),
                                          ),
                                        ),
                                        child: const Text(
                                          'Create an account',
                                          style: TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

// _AuthBackdrop and _BackdropOrb were removed; decorative-only, unused.

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final FaIconData icon;

  const _AuthHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: FaIcon(icon, color: AppTheme.primary, size: 28),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButtons extends StatelessWidget {
  final Future<void> Function(String provider)? onPressed;
  const _SocialButtons({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: onPressed == null ? null : () => onPressed!('Google'),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDB4437).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const FaIcon(
                FontAwesomeIcons.google,
                color: Color(0xFFDB4437),
                size: 14,
              ),
            ),
            label: const Text('Google'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 46),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onPressed == null ? null : () => onPressed!('GitHub'),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const FaIcon(
                FontAwesomeIcons.github,
                color: Colors.black87,
                size: 14,
              ),
            ),
            label: const Text('GitHub'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 46),
            ),
          ),
        ],
      ),
    );
  }
}
