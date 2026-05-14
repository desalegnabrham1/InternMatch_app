import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../admin/admin_dashboard_screen.dart';
import '../company/company_dashboard_screen.dart';
import '../user/user_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _extraController = TextEditingController();
  final _authService = AuthService();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  final FocusNode _extraFocus = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isStudent = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _extraController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _extraFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final role = _isStudent ? AppConstants.roleUser : AppConstants.roleCompany;
    final profileData = <String, Object?>{
      if (_isStudent)
        'fullName': _nameController.text.trim()
      else
        'companyName': _nameController.text.trim(),
      if (_isStudent)
        'headline': _extraController.text.trim()
      else
        'website': _extraController.text.trim(),
    };

    final error = await _authService.register(
      _emailController.text.trim(),
      _passwordController.text,
      role,
      profileData,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created successfully.')),
    );
    Navigator.of(context).maybePop();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    // After successful social sign-in, redirect to appropriate dashboard
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

    // Refresh token in background
    _authService.refreshIdToken();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = _isStudent ? 'student' : 'company';
    final nameLabel = _isStudent ? 'Full name' : 'Company name';
    final extraLabel = _isStudent ? 'Headline' : 'Website';
    final extraHint = _isStudent
        ? 'e.g. Final-year computer science student'
        : 'e.g. https://your-company.com';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Column(
            children: [
              _AuthHeader(
                title: 'Create account',
                subtitle: 'Join as a student or company',
                icon: FontAwesomeIcons.userPlus,
                onBack: () => Navigator.pop(context),
              ),
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
                                              'Tell us who you are',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Choose your account type and fill in the details below.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            const SizedBox(height: 18),
                                            Row(
                                              children: [
                                                _RoleCard(
                                                  label: 'Student',
                                                  subtitle:
                                                      'Look for internships',
                                                  icon: FontAwesomeIcons
                                                      .userGraduate,
                                                  selected: _isStudent,
                                                  onTap: () {
                                                    setState(() {
                                                      _isStudent = true;
                                                    });
                                                  },
                                                ),
                                                const SizedBox(width: 10),
                                                _RoleCard(
                                                  label: 'Company',
                                                  subtitle:
                                                      'Post and manage roles',
                                                  icon:
                                                      FontAwesomeIcons.building,
                                                  selected: !_isStudent,
                                                  onTap: () {
                                                    setState(() {
                                                      _isStudent = false;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 18),
                                            _SectionLabel(label: nameLabel),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _nameController,
                                              focusNode: _nameFocus,
                                              enabled: true,
                                              cursorColor: AppTheme.primary,
                                              textInputAction:
                                                  TextInputAction.next,
                                              onFieldSubmitted: (_) =>
                                                  _emailFocus.requestFocus(),
                                              decoration: InputDecoration(
                                                hintText: _isStudent
                                                    ? 'e.g. Abebe Kebede'
                                                    : 'e.g. Acme Technologies',
                                                prefixIcon: const Icon(
                                                    Icons.person_outline),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return _isStudent
                                                      ? AppConstants
                                                          .valNameRequired
                                                      : AppConstants
                                                          .valCompanyNameRequired;
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 14),
                                            _SectionLabel(
                                              label: _isStudent
                                                  ? 'Email address'
                                                  : 'Work email address',
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
                                                prefixIcon:
                                                    Icon(Icons.email_outlined),
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
                                            const _SectionLabel(
                                                label: 'Password'),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _passwordController,
                                              focusNode: _passwordFocus,
                                              obscureText: _obscurePassword,
                                              cursorColor: AppTheme.primary,
                                              textInputAction:
                                                  TextInputAction.next,
                                              onFieldSubmitted: (_) =>
                                                  _confirmFocus.requestFocus(),
                                              decoration: InputDecoration(
                                                hintText: 'Create a password',
                                                prefixIcon: const Icon(
                                                    Icons.lock_outline),
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
                                            const SizedBox(height: 14),
                                            const _SectionLabel(
                                              label: 'Confirm password',
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _confirmController,
                                              focusNode: _confirmFocus,
                                              obscureText: _obscureConfirm,
                                              cursorColor: AppTheme.primary,
                                              textInputAction:
                                                  TextInputAction.next,
                                              onFieldSubmitted: (_) =>
                                                  _extraFocus.requestFocus(),
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Re-enter your password',
                                                prefixIcon: const Icon(
                                                    Icons.lock_outline),
                                                suffixIcon: IconButton(
                                                  icon: FaIcon(
                                                    _obscureConfirm
                                                        ? FontAwesomeIcons.eye
                                                        : FontAwesomeIcons
                                                            .eyeSlash,
                                                    size: 17,
                                                  ),
                                                  onPressed: () => setState(
                                                    () => _obscureConfirm =
                                                        !_obscureConfirm,
                                                  ),
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value !=
                                                    _passwordController.text) {
                                                  return AppConstants
                                                      .valPasswordMatch;
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 14),
                                            _SectionLabel(label: extraLabel),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _extraController,
                                              focusNode: _extraFocus,
                                              keyboardType: _isStudent
                                                  ? TextInputType.text
                                                  : TextInputType.url,
                                              cursorColor: AppTheme.primary,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onFieldSubmitted: (_) =>
                                                  _register(),
                                              decoration: InputDecoration(
                                                hintText: extraHint,
                                                prefixIcon: Icon(
                                                  _isStudent
                                                      ? Icons.badge_outlined
                                                      : Icons.language,
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return _isStudent
                                                      ? 'Please enter a $roleLabel headline'
                                                      : 'Please enter your website or portfolio URL';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 24),
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
                                                    _loading ? null : _register,
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
                                                          Text(
                                                            'Creating account...',
                                                          ),
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
                                                          Text(
                                                              'Create Account'),
                                                        ],
                                                      ),
                                              ),
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
                                        'Already have an account? ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _SocialButtons(
                                    onPressed: _loading ? null : _socialSignIn,
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

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final FaIconData icon;
  final VoidCallback? onBack;

  const _AuthHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onBack,
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
          child: Stack(
            children: [
              if (onBack != null)
                Positioned(
                  left: 0,
                  top: 0,
                  child: IconButton(
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowLeft,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              Center(
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
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
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

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final FaIconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.10)
                : Theme.of(context).cardTheme.color ?? AppTheme.surface,
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.divider,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              FaIcon(
                icon,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.75)
                      : AppTheme.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
