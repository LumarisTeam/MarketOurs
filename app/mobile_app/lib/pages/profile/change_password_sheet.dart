import 'package:flutter/cupertino.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../ui/app_feedback.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';
import '../../utils/dto_validation.dart';
import '../auth/password_form_field.dart';

class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
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
      await AppFeedback.showSuccess(
        context,
        message: AppLocalizations.of(context).passwordChanged,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
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

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              l10n.profileChangePasswordTitle,
              style: AppTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: 20),
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
