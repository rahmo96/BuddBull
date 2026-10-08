import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/auth/presentation/widgets/password_strength_indicator.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/l10n/l10n.dart';
import 'package:buddbull/shared/widgets/app_logo.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  static const String _defaultRole = 'player'; // l10n-ignore: API role value
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
      showErrorSnackBar(context, context.l10n.validationAcceptTerms);
      return;
    }
    ref.read(authProvider.notifier).register(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _defaultRole,
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
                        color: Colors.black.withValues(alpha: 0.06),
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
                        Text(context.l10n.authRegisterTitle,
                            style: AppTextStyles.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.authRegisterSubtitle,
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
                                label: context.l10n.authFirstNameLabel,
                                hint: context.l10n.authFirstNameHint,
                                controller: _firstNameCtrl,
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? context.l10n.validationFieldRequired
                                    : null,
                              ),
                            ),
                            Expanded(
                              child: BbTextField(
                                label: context.l10n.authLastNameLabel,
                                hint: context.l10n.authLastNameHint,
                                controller: _lastNameCtrl,
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? context.l10n.validationFieldRequired
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Username ──────────────────────────
                        BbTextField(
                          label: context.l10n.authUsernameLabel,
                          hint: context.l10n.authUsernameHint,
                          controller: _usernameCtrl,
                          prefixIcon: Icons.alternate_email_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return context.l10n.validationFieldRequired;
                            }
                            if (v.trim().length < 3) {
                              return context.l10n.validationUsernameTooShort;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Email ─────────────────────────────
                        BbTextField(
                          label: context.l10n.authEmailLabel,
                          hint: context.l10n.authEmailHint,
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return context.l10n.validationFieldRequired;
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                .hasMatch(v.trim())) {
                              return context.l10n.validationInvalidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Password ──────────────────────────
                        BbTextField(
                          label: context.l10n.authPasswordLabel,
                          hint: context.l10n.authNewPasswordHint,
                          controller: _passwordCtrl,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline_rounded,
                          onChanged: (v) => setState(() => _password = v),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return context.l10n.validationFieldRequired;
                            }
                            if (v.length < 8) {
                              return context.l10n.validationPasswordTooShort;
                            }
                            return null;
                          },
                        ),
                        PasswordStrengthIndicator(password: _password),
                        const SizedBox(height: 16),

                        // ── Confirm password ──────────────────
                        BbTextField(
                          label: context.l10n.authConfirmPasswordLabel,
                          hint: context.l10n.authConfirmPasswordHint,
                          controller: _confirmCtrl,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline_rounded,
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            if (v != _passwordCtrl.text) {
                              return context.l10n.validationPasswordsNoMatch;
                            }
                            return null;
                          },
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
                          label: context.l10n.authRegisterButton,
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
                    context.l10n.authHaveAccount,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(Routes.login),
                    child: Text(context.l10n.authSignInLink),
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
                AppLogo(size: 48, borderRadius: 14),
                SizedBox(width: 10),
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontFamilyFallback: ['Heebo'],
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
                TextSpan(text: context.l10n.authTermsAgreement),
                TextSpan(
                  text: context.l10n.authTermsOfService,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                TextSpan(text: context.l10n.authTermsAnd),
                TextSpan(
                  text: context.l10n.authPrivacyPolicy,
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
