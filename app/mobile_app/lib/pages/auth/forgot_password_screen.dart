import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/slider_captcha.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';
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

      await McFeedback.showSuccess(
        context,
        message: AppLocalizations.of(context).verifyCodeSentContinue,
      );
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
      await McFeedback.showError(
        context,
        message: (errorMessage != null && errorMessage.isNotEmpty)
            ? errorMessage
            : AppLocalizations.of(context).authSendCodeFailed,
      );
    }
  }

  Future<String?> _showCaptcha() {
    final l10n = AppLocalizations.of(context);
    return showMcDialog<String>(
      context: context,
      barrierDismissible: false,
      title: l10n.captchaComplete,
      message: l10n.captchaDragSlider,
      content: Builder(
        builder: (dialogContext) => SliderCaptcha(
          onVerify: (token) => Navigator.of(dialogContext).pop(token),
          onCancel: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
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
            McField.text(
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
            McButton.primary(
              onPressed: isSubmitting ? null : _submit,
              child: Text(
                isSubmitting
                    ? AppLocalizations.of(context).profileSaving
                    : AppLocalizations.of(context).authSendCode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
