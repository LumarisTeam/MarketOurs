import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_permissions_service.dart';
import '../../ui/app_responsive.dart';

/// Settings page for the runtime permissions requested by the app.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen>
    with WidgetsBindingObserver {
  AppPermissionsSnapshot? _snapshot;
  bool _isLoading = true;
  bool _loadFailed = false;
  final Set<AppPermissionKind> _requesting = <AppPermissionKind>{};

  AppPermissionsService get _service => ref.read(appPermissionsServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load(showLoading: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh after the user comes back from the system settings page.
    if (state == AppLifecycleState.resumed) {
      _load(showLoading: false);
    }
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }

    try {
      final snapshot = await _service.load();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _handlePermissionTap(AppPermissionState permission) async {
    if (_requesting.contains(permission.kind)) return;

    if (permission.isGranted || permission.needsSystemSettings) {
      await _showManageDialog();
      return;
    }

    await _requestPermission(permission.kind);
  }

  Future<void> _requestPermission(AppPermissionKind kind) async {
    setState(() => _requesting.add(kind));

    try {
      final status = await _service.request(kind);
      if (!mounted) return;

      if (status.isGranted || status.isLimited || status.isProvisional) {
        unawaited(
          McFeedback.showSuccess(
            context,
            message: AppLocalizations.of(context).permissionGrantedToast,
          ),
        );
      } else if (status.isPermanentlyDenied || status.isRestricted) {
        await _showManageDialog();
      } else {
        unawaited(
          McFeedback.showError(
            context,
            message: AppLocalizations.of(context).permissionRequestDenied,
          ),
        );
      }

      if (mounted) await _load(showLoading: false);
    } catch (_) {
      if (mounted) {
        await McFeedback.showError(
          context,
          message: AppLocalizations.of(context).permissionRequestFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _requesting.remove(kind));
    }
  }

  Future<void> _showManageDialog() async {
    final l10n = AppLocalizations.of(context);
    final shouldOpen = await showMcConfirmDialog(
      context: context,
      title: l10n.permissionManageDialogTitle,
      message: l10n.permissionManageDialogMessage,
      cancelText: l10n.cancel,
      confirmText: l10n.permissionOpenSettings,
    );

    if (shouldOpen == true) {
      await _openSystemSettings();
    }
  }

  Future<void> _openSystemSettings() async {
    try {
      await _service.openSettings();
    } catch (_) {
      if (mounted) {
        await McFeedback.showError(
          context,
          message: AppLocalizations.of(context).permissionRequestFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot = _snapshot;

    return McPageScaffold(
      title: l10n.permissionSettingsTitle,
      navigationBarStyle: McNavigationBarStyle.compact,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _isLoading ? null : () => _load(),
        child: _isLoading
            ? const CupertinoActivityIndicator(radius: 8)
            : const Icon(CupertinoIcons.refresh, size: 22),
      ),
      slivers: [
        if (_isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (_loadFailed)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: McEmpty.retry(
                  title: l10n.permissionLoadFailed,
                  description: l10n.permissionLoadFailedDesc,
                  onRetry: () => _load(),
                  retryLabel: l10n.retry,
                ),
              ),
            ),
          )
        else if (snapshot == null || !snapshot.isSupported)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: McEmpty.placeholder(
                  icon: CupertinoIcons.lock_shield,
                  title: l10n.permissionUnsupportedTitle,
                  description: l10n.permissionUnsupportedDesc,
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: AppResponsiveCenter(
              maxWidth: AppResponsive.readableMaxWidth(context, fallback: 720),
              padding: AppResponsive.sliverPagePadding(
                context,
                top: 16,
                bottom: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PermissionsSummaryCard(snapshot: snapshot),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      l10n.permissionSectionTitle,
                      style: context.mc.textLabel,
                    ),
                  ),
                  McCard.grouped(
                    child: Column(
                      children: [
                        for (
                          var i = 0;
                          i < snapshot.permissions.length;
                          i++
                        ) ...[
                          if (i > 0)
                            Container(
                              height: 1,
                              margin: const EdgeInsets.only(left: 52),
                              color: context.mc.border.withValues(alpha: 0.3),
                            ),
                          _PermissionRow(
                            permission: snapshot.permissions[i],
                            isRequesting: _requesting.contains(
                              snapshot.permissions[i].kind,
                            ),
                            onTap: () =>
                                _handlePermissionTap(snapshot.permissions[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      l10n.permissionSettingsHint,
                      style: context.mc.textMuted.copyWith(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 22),
                  McButton.secondary(
                    onPressed: _openSystemSettings,
                    child: Text(l10n.permissionOpenSettings),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PermissionsSummaryCard extends StatelessWidget {
  const _PermissionsSummaryCard({required this.snapshot});

  final AppPermissionsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return McCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.mc.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              CupertinoIcons.lock_shield,
              color: context.mc.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.permissionSummary(
                    snapshot.grantedCount,
                    snapshot.totalCount,
                  ),
                  style: context.mc.textSection,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.permissionSettingsIntro,
                  style: context.mc.textMuted.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.permission,
    required this.isRequesting,
    required this.onTap,
  });

  final AppPermissionState permission;
  final bool isRequesting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return McListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: isRequesting ? null : onTap,
      leading: Icon(
        _iconFor(permission.kind),
        color: _colorFor(context, permission.kind),
        size: 24,
      ),
      title: Text(
        _titleFor(permission.kind, l10n),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          _descriptionFor(permission.kind, l10n),
          style: TextStyle(
            color: context.mc.secondaryLabel,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRequesting)
            const CupertinoActivityIndicator(radius: 8)
          else
            _PermissionStatusBadge(status: permission.status),
          const SizedBox(width: 6),
          Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: context.mc.tertiaryLabel,
          ),
        ],
      ),
    );
  }

  static String _titleFor(AppPermissionKind kind, AppLocalizations l10n) {
    return switch (kind) {
      AppPermissionKind.notifications => l10n.permissionNotificationsTitle,
      AppPermissionKind.camera => l10n.permissionCameraTitle,
      AppPermissionKind.photos => l10n.permissionPhotosTitle,
    };
  }

  static String _descriptionFor(AppPermissionKind kind, AppLocalizations l10n) {
    return switch (kind) {
      AppPermissionKind.notifications => l10n.permissionNotificationsDesc,
      AppPermissionKind.camera => l10n.permissionCameraDesc,
      AppPermissionKind.photos => l10n.permissionPhotosDesc,
    };
  }

  static IconData _iconFor(AppPermissionKind kind) {
    return switch (kind) {
      AppPermissionKind.notifications => CupertinoIcons.bell_fill,
      AppPermissionKind.camera => CupertinoIcons.camera_fill,
      AppPermissionKind.photos => CupertinoIcons.photo_fill_on_rectangle_fill,
    };
  }

  static Color _colorFor(BuildContext context, AppPermissionKind kind) {
    return switch (kind) {
      AppPermissionKind.notifications => context.mc.primary,
      AppPermissionKind.camera => context.mc.indigo,
      AppPermissionKind.photos => context.mc.purple,
    };
  }
}

class _PermissionStatusBadge extends StatelessWidget {
  const _PermissionStatusBadge({required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (status) {
      PermissionStatus.granted => (
        l10n.permissionStatusGranted,
        context.mc.success,
      ),
      PermissionStatus.limited || PermissionStatus.provisional => (
        l10n.permissionStatusLimited,
        context.mc.warning,
      ),
      PermissionStatus.permanentlyDenied => (
        l10n.permissionStatusPermanentlyDenied,
        context.mc.destructive,
      ),
      PermissionStatus.restricted => (
        l10n.permissionStatusRestricted,
        context.mc.warning,
      ),
      PermissionStatus.denied => (
        l10n.permissionStatusDenied,
        context.mc.secondaryLabel,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
