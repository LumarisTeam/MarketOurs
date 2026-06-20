import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../ui/app_feedback.dart';
import '../../ui/app_fields.dart';
import '../../ui/app_widgets.dart';
import '../../widgets/slider_captcha.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final captchaToken = await _showCaptcha();
    if (captchaToken == null) return;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .forgotPassword(
            account: _accountController.text.trim(),
            captchaToken: captchaToken,
          );

      if (!mounted) {
        return;
      }

      await AppFeedback.showSuccess(context, message: AppLocalizations.of(context).verifyCodeSentContinue);
      if (!mounted) {
        return;
      }
      context.goNamed(
        AppRouteNames.resetPassword,
        queryParameters: {'account': _accountController.text.trim()},
      );
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
            : AppLocalizations.of(context).authSendCodeFailed,
      );
    }
  }

  Future<String?> _showCaptcha() {
    final completer = Completer<String?>();
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SliderCaptcha(
        onVerify: (token) {
          Navigator.of(ctx).pop();
          completer.complete(token);
        },
        onCancel: () {
          Navigator.of(ctx).pop();
          completer.complete();
        },
      ),
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider).asData?.value;
    final isSubmitting = authState?.isSubmitting ?? false;

    return AuthScaffold(
      title: AppLocalizations.of(context).authForgotPassword,
      footer: Center(
        child: CupertinoButton(
          onPressed: isSubmitting
              ? null
              : () => context.go(AppRoutePaths.login),
          child: Text(
            AppLocalizations.of(context).authAlreadyHaveAccount,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _accountController,
              placeholder: AppLocalizations.of(context).authAccountPlaceholder,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context).validatorAccountRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              onPressed: isSubmitting ? null : _submit,
              child: Text(isSubmitting ? AppLocalizations.of(context).profileSaving : AppLocalizations.of(context).authSendCode),
            ),
          ],
        ),
      ),
    );
  }
}
