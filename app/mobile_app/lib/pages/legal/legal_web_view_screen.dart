import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:luamris_ui/luamris_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../l10n/app_localizations.dart';

/// Renders a legal document hosted on the web inside an in-app WebView.
class LegalWebViewScreen extends StatefulWidget {
  const LegalWebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final Uri url;

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  WebViewController? _controller;
  int _progress = 0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _backgroundApplied = false;

  /// webview_flutter only ships Android, iOS and macOS implementations.
  bool get _supportsWebView =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    if (_supportsWebView) {
      _controller = _createController()..loadRequest(widget.url);
    } else {
      // Desktop-only builds (Linux/Windows) fall back to the system browser.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openExternally());
    }
  }

  WebViewController _createController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted || progress == _progress) return;
            setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            // Failures of sub-resources (fonts, analytics) must not blank the page.
            if (!mounted || error.isForMainFrame == false) return;
            // iOS reports NSURLErrorCancelled (-999) when a navigation is superseded.
            if (error.errorCode == -999) return;
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_backgroundApplied) return;
    _backgroundApplied = true;
    // Match the WebView canvas to the app theme so dark mode does not flash white.
    _controller?.setBackgroundColor(context.mc.background);
  }

  Future<void> _reload() async {
    final controller = _controller;
    if (controller == null) {
      await _openExternally();
      return;
    }

    setState(() {
      _progress = 0;
      _isLoading = true;
      _hasError = false;
    });
    await controller.loadRequest(widget.url);
  }

  Future<void> _openExternally() async {
    try {
      await launchUrl(widget.url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      McFeedback.showError(
        context,
        message: AppLocalizations.of(context).oauthWebViewCantOpenBrowser,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: context.mc.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.title,
          style: TextStyle(
            color: context.mc.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: context.mc.background.withValues(alpha: 0.82),
        border: Border(
          bottom: BorderSide(color: context.mc.border.withValues(alpha: 0.35)),
        ),
      ),
      child: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;
    if (controller == null) {
      return _buildExternalFallback(context, l10n);
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: McEmpty.retry(
            title: l10n.errorNetworkFailed,
            description: widget.url.toString(),
            onRetry: _reload,
            retryLabel: l10n.retry,
          ),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (_isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SizedBox(
                height: 2,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress <= 0
                      ? 0.05
                      : (_progress / 100).clamp(0.0, 1.0),
                  child: ColoredBox(color: context.mc.primary),
                ),
              ),
            ),
          ),
        if (_isLoading && _progress < 20)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            ),
          ),
      ],
    );
  }

  Widget _buildExternalFallback(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 40,
              color: context.mc.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: context.mc.textSection,
            ),
            const SizedBox(height: 8),
            Text(
              widget.url.toString(),
              textAlign: TextAlign.center,
              style: context.mc.textMuted.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 20),
            McButton.secondary(
              onPressed: _openExternally,
              child: Text(l10n.legalOpenInBrowser),
            ),
          ],
        ),
      ),
    );
  }
}
