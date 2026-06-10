import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../services/auth_service.dart';
import '../../ui/app_feedback.dart';
import '../../ui/app_theme.dart';

class OAuthWebViewScreen extends ConsumerStatefulWidget {
  const OAuthWebViewScreen({super.key, required this.provider});

  final String provider;

  @override
  ConsumerState<OAuthWebViewScreen> createState() =>
      _OAuthWebViewScreenState();
}

class _OAuthWebViewScreenState extends ConsumerState<OAuthWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final provider = widget.provider;
    final returnUrl = AuthService.oauthCallbackUrl;
    final loginUrl = AuthService().buildExternalLoginUrl(
      provider: provider,
      returnUrl: returnUrl,
      purpose: 'login',
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() => _progress = progress / 100.0);
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (url.startsWith(AuthService.oauthCallbackUrl)) {
              _handleCallback(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(loginUrl));
  }

  void _handleCallback(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _fail('无法解析回调地址');
      return;
    }

    final error = uri.queryParameters['error'];
    if (error != null) {
      _fail(error);
      return;
    }

    final accessToken = uri.queryParameters['accessToken'];
    final refreshToken = uri.queryParameters['refreshToken'];

    if (accessToken == null || refreshToken == null) {
      _fail('登录失败，缺少令牌');
      return;
    }

    _processTokens(accessToken, refreshToken);
  }

  Future<void> _processTokens(String accessToken, String refreshToken) async {
    try {
      final success = await ref
          .read(authControllerProvider.notifier)
          .handleOAuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );

      if (!mounted) return;

      if (success) {
        await AppFeedback.showSuccess(context, message: '登录成功');
        if (!mounted) return;
        context.go(AppRoutePaths.home);
      } else {
        final authState = ref.read(authControllerProvider).asData?.value;
        final errorMessage = authState?.errorMessage;
        _fail(errorMessage ?? '登录失败，请稍后重试');
      }
    } catch (error) {
      if (!mounted) return;
      _fail('登录失败，请稍后重试');
    }
  }

  void _fail(String message) {
    AppFeedback.showError(
      context,
      message: message,
    );
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${widget.provider} 登录'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.xmark),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            if (_controller != null)
              WebViewWidget(controller: _controller!),
            if (_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress > 0 ? _progress : null,
                    child: Container(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
