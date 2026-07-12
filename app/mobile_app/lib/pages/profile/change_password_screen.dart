import 'package:flutter/cupertino.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../ui/app_feedback.dart';
import '../../ui/app_responsive.dart';
import '../../ui/app_widgets.dart';
import '../../utils/dto_validation.dart';
import '../auth/password_form_field.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) {
        return;
      }
      await AppFeedback.showSuccess(context, message: AppLocalizations.of(context).passwordChanged);
      if (!mounted) {
        return;
      }
      context.go(AppRoutePaths.profile);
    } catch (_) {
      final errorMessage = ref
          .read(authControllerProvider)
          .asData
          ?.value
          .errorMessage;
      await AppFeedback.showError(
        context,
        message: (errorMessage != null && errorMessage.isNotEmpty)
            ? errorMessage
            : AppLocalizations.of(context).authChangePasswordFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider).asData?.value;
    final isSubmitting = authState?.isSubmitting ?? false;

    return AppPageScaffold(
      title: l10n.profileChangePasswordTitle,
      navigationBarStyle: AppNavigationBarStyle.compact,
      maxContentWidth: AppResponsive.readableMaxWidth(context, fallback: 560),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            PasswordFormField(
              controller: _oldPasswordController,
              placeholder: l10n.currentPasswordPlaceholder,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterCurrentPassword;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            PasswordFormField(
              controller: _newPasswordController,
              placeholder: l10n.newPasswordPlaceholder,
              maxLength: DtoLimits.userPasswordMax,
              validator: (value) {
                return passwordLengthValidator(
                  value,
                  emptyMessage: l10n.enterNewPassword,
                  minMessage: l10n.passwordMinLength(DtoLimits.userPasswordMin),
                  maxMessage: l10n.passwordMaxLength(DtoLimits.userPasswordMax),
                );
              },
            ),
            const SizedBox(height: 16),
            PasswordFormField(
              controller: _confirmPasswordController,
              placeholder: l10n.confirmPasswordPlaceholder,
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return l10n.passwordsMismatch;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              onPressed: isSubmitting ? null : _submit,
              child: Text(isSubmitting ? l10n.profileSubmitting : l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
