import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/slider_captcha.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../services/error_messages.dart';
import 'auth_scaffold.dart';
import 'password_form_field.dart';

enum _LoginMode { password, otp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  _LoginMode _loginMode = _LoginMode.password;
  Timer? _countdownTimer;
  int _countdown = 0;
  bool _isSendingCode = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _accountController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final account = _accountController.text.trim();
    if (account.isEmpty) {
      await McFeedback.showError(
        context,
        message: AppLocalizations.of(context).validatorAccountRequired,
      );
      return;
    }

    final captchaToken = await _showCaptcha();
    if (captchaToken == null || !mounted) return;

    setState(() => _isSendingCode = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendLoginCode(account: account, captchaToken: captchaToken);
      if (!mounted) return;
      _startCountdown();
      await McFeedback.showSuccess(
        context,
        message: AppLocalizations.of(context).authSendCodeSuccess,
      );
    } catch (error) {
      if (!mounted) return;
      await McFeedback.showError(
        context,
        message: extractErrorFromException(error),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
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

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _countdown = 0);
        }
        return;
      }

      if (mounted) {
        setState(() => _countdown -= 1);
      }
    });
  }

  void _handleOAuthLogin(String provider) {
    final location = Uri(
      path: AppRoutePaths.oauthWebView,
      queryParameters: {
        'provider': provider,
        '_ts': DateTime.now().microsecondsSinceEpoch.toString(),
      },
    ).toString();
    context.push(location);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      await McFeedback.showError(
        context,
        message: AppLocalizations.of(context).authMustAgreeTerms,
      );
      return;
    }

    final notifier = ref.read(authControllerProvider.notifier);
    final success = _loginMode == _LoginMode.password
        ? await notifier.login(
            account: _accountController.text.trim(),
            password: _passwordController.text,
          )
        : await notifier.loginByCode(
            account: _accountController.text.trim(),
            code: _otpController.text.trim(),
          );

    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider).asData?.value;
    final errorMessage = authState?.errorMessage;
    if (success) {
      await McFeedback.showSuccess(
        context,
        message: AppLocalizations.of(context).authLoginSuccess,
      );
      if (!mounted) {
        return;
      }
      context.go(AppRoutePaths.home);
      return;
    }

    final fallbackMessage = _loginMode == _LoginMode.password
        ? AppLocalizations.of(context).loginFailedCheckAccount
        : AppLocalizations.of(context).loginFailedCheckCode;
    await McFeedback.showError(
      context,
      message: (errorMessage != null && errorMessage.isNotEmpty)
          ? errorMessage
          : fallbackMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider).asData?.value;
    final isSubmitting = authState?.isSubmitting ?? false;

    return AuthScaffold(
      title: AppLocalizations.of(context).authLogin,
      footer: Center(
        child: CupertinoButton(
          onPressed: isSubmitting
              ? null
              : () => context.go(AppRoutePaths.register),
          child: Text(
            AppLocalizations.of(context).authNoAccount,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CupertinoSlidingSegmentedControl<_LoginMode>(
              groupValue: _loginMode,
              onValueChanged: (value) {
                if (value != null) setState(() => _loginMode = value);
              },
              children: {
                _LoginMode.password: Text(
                  AppLocalizations.of(context).authPasswordLogin,
                ),
                _LoginMode.otp: Text(
                  AppLocalizations.of(context).authCodeLogin,
                ),
              },
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).authAccount,
              style: context.mc.textLabel,
            ),
            const SizedBox(height: 8),
            McField.text(
              controller: _accountController,
              placeholder: AppLocalizations.of(context).authAccountPlaceholder,
              prefix: Icon(
                CupertinoIcons.mail,
                color: context.mc.secondaryLabel,
                size: 18,
              ),
              textInputAction: _loginMode == _LoginMode.password
                  ? TextInputAction.next
                  : TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context).validatorAccountRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            if (_loginMode == _LoginMode.password) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).authPassword,
                    style: context.mc.textLabel,
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: isSubmitting
                        ? null
                        : () => context.go(AppRoutePaths.forgotPassword),
                    child: Text(
                      AppLocalizations.of(context).authForgotPasswordPrompt,
                      style: TextStyle(
                        color: context.mc.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PasswordFormField(
                controller: _passwordController,
                placeholder: AppLocalizations.of(context)
                    .validatorPasswordRequired,
                onFieldSubmitted: (_) => isSubmitting ? null : _submit(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)
                        .validatorPasswordRequired;
                  }
                  return null;
                },
              ),
            ] else ...[
              Text(
                AppLocalizations.of(context).authVerificationCode,
                style: context.mc.textLabel,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: McField.text(
                      controller: _otpController,
                      placeholder: AppLocalizations.of(context)
                          .authCodePlaceholder,
                      keyboardType: TextInputType.number,
                      prefix: Icon(
                        CupertinoIcons.shield_fill,
                        color: context.mc.secondaryLabel,
                        size: 18,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)
                              .validatorCodeRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: McButton.secondary(
                      onPressed:
                          isSubmitting || _isSendingCode || _countdown > 0
                          ? null
                          : _sendCode,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _isSendingCode
                            ? AppLocalizations.of(context).profileSaving
                            : _countdown > 0
                            ? '${_countdown}s'
                            : AppLocalizations.of(context).authSendCode,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            GestureDetector(
              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _agreedToTerms
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    size: 20,
                    color: _agreedToTerms
                        ? context.mc.primary
                        : context.mc.secondaryLabel,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: context.mc.secondaryLabel,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${AppLocalizations.of(context).authAgreeToTermsPrefix} ',
                          ),
                          TextSpan(
                            text: AppLocalizations.of(context).termsOfService,
                            style: TextStyle(
                              color: context.mc.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => context.push(AppRoutePaths.terms),
                          ),
                          TextSpan(
                            text: ' ${AppLocalizations.of(context).authAnd} ',
                          ),
                          TextSpan(
                            text: AppLocalizations.of(context).privacyPolicy,
                            style: TextStyle(
                              color: context.mc.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  context.push(AppRoutePaths.privacy),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            McButton.primary(
              onPressed: isSubmitting || !_agreedToTerms ? null : _submit,
              child: Text(
                isSubmitting
                    ? AppLocalizations.of(context).profileSaving
                    : AppLocalizations.of(context).authLogin,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: context.mc.border.withValues(alpha: 0.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    AppLocalizations.of(context).oauthOtherMethods,
                    style: context.mc.textLabel.copyWith(
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: context.mc.border.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(
                  icon: CupertinoIcons.person_circle,
                  label: 'Ours',
                  onPressed: () => _handleOAuthLogin('Ours'),
                ),
                const SizedBox(width: 24),
                _SocialButton(
                  icon: CupertinoIcons.globe,
                  label: 'Google',
                  onPressed: () => _handleOAuthLogin('Google'),
                ),
                const SizedBox(width: 24),
                _SocialButton(
                  icon: CupertinoIcons.cloud,
                  label: 'Github',
                  onPressed: () => _handleOAuthLogin('Github'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                color: context.mc.border.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(McRadii.md),
            ),
            child: Icon(icon, size: 24, color: context.mc.foreground),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: context.mc.textLabel.copyWith(fontSize: 10)),
      ],
    );
  }
}
