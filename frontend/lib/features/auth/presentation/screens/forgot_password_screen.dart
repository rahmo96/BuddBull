import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/l10n/l10n.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref
        .read(authProvider.notifier)
        .forgotPassword(_emailCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        showErrorSnackBar(context, next.error!);
        ref.read(authProvider.notifier).clearError();
      }
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        showSuccessSnackBar(context, next.successMessage!);
        ref.read(authProvider.notifier).clearSuccess();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Icon ──────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // ── Title ──────────────────────────────────────────
              Text(context.l10n.authResetPasswordTitle,
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(
                context.l10n.authForgotSubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // ── Form ───────────────────────────────────────────
              Form(
                key: _formKey,
                child: BbTextField(
                  label: context.l10n.authEmailLabel,
                  hint: context.l10n.authEmailHint,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
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
              ),
              const SizedBox(height: 28),

              // ── Submit ─────────────────────────────────────────
              BbButton(
                label: context.l10n.authSendResetLink,
                onPressed: _submit,
                isLoading: authState.isSubmitting,
              ),
              const SizedBox(height: 16),

              // ── Back ───────────────────────────────────────────
              BbButton(
                label: context.l10n.authBackToLogin,
                onPressed: () => context.pop(),
                variant: BbButtonVariant.ghost,
              ),

              const SizedBox(height: 32),

              // ── Info card ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.info, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.authResetInfo,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
                        ),
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
