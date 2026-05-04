import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/auth/presentation/screens/login_screen.dart';
import 'package:buddbull/features/auth/presentation/widgets/password_strength_indicator.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:buddbull/shared/widgets/error_view.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _role = 'player';
  bool _acceptedTerms = false;
  String _password = '';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      showErrorSnackBar(context, AppStrings.acceptTerms);
      return;
    }
    ref.read(authProvider.notifier).register(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        showErrorSnackBar(context, next.error!);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            _RegisterHeader(),

            // ── Form ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(AppStrings.createAccount,
                            style: AppTextStyles.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.registerSubtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Name row ──────────────────────────
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: BbTextField(
                                label: AppStrings.firstNameLabel,
                                hint: AppStrings.firstNameHint,
                                controller: _firstNameCtrl,
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? AppStrings.fieldRequired
                                    : null,
                              ),
                            ),
                            Expanded(
                              child: BbTextField(
                                label: AppStrings.lastNameLabel,
                                hint: AppStrings.lastNameHint,
                                controller: _lastNameCtrl,
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? AppStrings.fieldRequired
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Username ──────────────────────────
                        BbTextField(
                          label: AppStrings.usernameLabel,
                          hint: AppStrings.usernameHint,
                          controller: _usernameCtrl,
                          prefixIcon: Icons.alternate_email_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return AppStrings.fieldRequired;
                            }
                            if (v.trim().length < 3) {
                              return AppStrings.usernameTooShort;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Email ─────────────────────────────
                        BbTextField(
                          label: AppStrings.emailLabel,
                          hint: AppStrings.emailHint,
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return AppStrings.fieldRequired;
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                .hasMatch(v.trim())) {
                              return AppStrings.invalidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Password ──────────────────────────
                        BbTextField(
                          label: AppStrings.passwordLabel,
                          hint: 'At least 8 characters',
                          controller: _passwordCtrl,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline_rounded,
                          onChanged: (v) => setState(() => _password = v),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return AppStrings.fieldRequired;
                            }
                            if (v.length < 8) {
                              return AppStrings.passwordTooShort;
                            }
                            return null;
                          },
                        ),
                        PasswordStrengthIndicator(password: _password),
                        const SizedBox(height: 16),

                        // ── Confirm password ──────────────────
                        BbTextField(
                          label: AppStrings.confirmPasswordLabel,
                          hint: AppStrings.confirmPasswordHint,
                          controller: _confirmCtrl,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline_rounded,
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            if (v != _passwordCtrl.text) {
                              return AppStrings.passwordsNoMatch;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // ── Role picker ───────────────────────
                        const Text(AppStrings.roleLabel,
                            style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        _RoleSelector(
                          selected: _role,
                          onChanged: (r) => setState(() => _role = r),
                        ),
                        const SizedBox(height: 20),

                        // ── Terms ─────────────────────────────
                        _TermsCheckbox(
                          accepted: _acceptedTerms,
                          onChanged: (v) =>
                              setState(() => _acceptedTerms = v ?? false),
                        ),
                        const SizedBox(height: 24),

                        // ── Submit ────────────────────────────
                        BbButton(
                          label: AppStrings.registerButton,
                          onPressed: _submit,
                          isLoading: authState.isSubmitting,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Sign in link ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.haveAccount,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(Routes.login),
                    child: const Text(AppStrings.signInLink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact header for register ───────────────────────────────────────────────
class _RegisterHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradientVertical,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: const SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🏆', style: TextStyle(fontSize: 28)),
                SizedBox(width: 10),
                Text(
                  'BuddBull',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Role selector ─────────────────────────────────────────────────────────────
class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: _RoleTile(
            value: 'player',
            label: 'Player',
            description: 'Join games',
            icon: Icons.sports_soccer_rounded,
            selected: selected == 'player',
            onTap: () => onChanged('player'),
          ),
        ),
        Expanded(
          child: _RoleTile(
            value: 'organizer',
            label: 'Organizer',
            description: 'Create games',
            icon: Icons.military_tech_rounded,
            selected: selected == 'organizer',
            onTap: () => onChanged('organizer'),
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.grey100,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? AppColors.primary : AppColors.grey500,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            Text(
              description,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Terms checkbox ────────────────────────────────────────────────────────────
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.accepted, required this.onChanged});
  final bool accepted;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-8, -4),
          child: Checkbox(
            value: accepted,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall,
              children: [
                const TextSpan(text: AppStrings.termsAgreement),
                TextSpan(
                  text: AppStrings.termsOfService,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                const TextSpan(text: AppStrings.andText),
                TextSpan(
                  text: AppStrings.privacyPolicy,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
