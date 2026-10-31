import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luamris_ui/luamris_ui.dart';

import '../../components/app_avatar.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../router/app_router.dart';
import '../../services/app_permissions_service.dart';
import '../../ui/app_responsive.dart';
import '../../utils/dto_validation.dart';
import 'change_password_sheet.dart';
import 'profile_edit_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDesktop = AppResponsive.isDesktop(context);
    final authState = ref.watch(authControllerProvider).asData?.value;
    final user = authState?.user;
    final isSubmitting = authState?.isSubmitting ?? false;

    if (user == null) {
      return CupertinoPageScaffold(
        backgroundColor: context.mc.background,
        child: CustomScrollView(
          slivers: [
            if (isDesktop)
              SliverToBoxAdapter(
                child: _ProfilePaneHeader(title: l10n.tabProfile),
              )
            else
              CupertinoSliverNavigationBar(
                largeTitle: Text(l10n.tabProfile),
                border: null,
              ),
            SliverFillRemaining(
              child: AppResponsiveCenter(
                maxWidth: isDesktop ? 780 : null,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      McEmpty.placeholder(
                        icon: CupertinoIcons.person,
                        title: l10n.profileNotLoggedIn,
                        description: l10n.profileNotLoggedInDesc,
                        action: McButton.primary(
                          onPressed: () => context.go(AppRoutePaths.login),
                          child: Text(l10n.profileGoLogin),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _ThemeModeSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sections = <Widget>[
      _ProfileSection(
        title: l10n.profileInfo,
        children: [
          _InfoRow(
            label: l10n.profileNickname,
            value: _fallback(user.name, l10n.profileNotSet),
          ),
          _InfoRow(
            label: l10n.profileBio,
            value: _fallback(user.info, l10n.profileNoBio),
          ),
          _InfoRow(
            label: l10n.profileEmail,
            value: _fallback(user.email, l10n.profileNoEmail),
          ),
          _VerificationRow(
            label: l10n.profileVerifyEmailTitle,
            isVerified: user.isEmailVerified ?? false,
            isBusy: isSubmitting,
            onVerify: () => _startVerification(
              context: context,
              ref: ref,
              sendCode: () =>
                  ref.read(authControllerProvider.notifier).sendEmailCode(),
              verifyCode: (code) => ref
                  .read(authControllerProvider.notifier)
                  .verifyEmailCode(code: code),
              successMessage: l10n.profileEmailVerifySuccess,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _ProfileSection(
        title: l10n.profileSocial,
        children: [
          _NavRow(
            icon: CupertinoIcons.person_2,
            title: l10n.profileFollowBlock,
            subtitle: l10n.profileFollowBlockDesc,
            onTap: () => context.push(AppRoutePaths.following),
          ),
          _NavRow(
            icon: CupertinoIcons.link,
            title: l10n.profileBindings,
            subtitle: l10n.profileManageSocialDesc,
            onTap: () => context.push(AppRoutePaths.bindings),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const _ThemeModeSection(),
      const SizedBox(height: 16),
      _ProfileSection(
        title: l10n.profileAppSettings,
        children: [
          _NavRow(
            icon: CupertinoIcons.lock_shield,
            title: l10n.permissionSettingsTitle,
            subtitle: l10n.permissionSettingsEntryDesc,
            onTap: () => context.push(AppRoutePaths.permissions),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _ProfileSection(
        title: l10n.profileAbout,
        children: [
          _NavRow(
            icon: CupertinoIcons.chat_bubble_2_fill,
            title: l10n.feedbackTitle,
            subtitle: l10n.feedbackSubtitle,
            onTap: () => context.push(AppRoutePaths.feedback),
          ),
          _NavRow(
            icon: CupertinoIcons.doc_text,
            title: l10n.profileTerms,
            subtitle: l10n.profileTermsDesc,
            onTap: () => context.push(AppRoutePaths.terms),
          ),
          _NavRow(
            icon: CupertinoIcons.shield_lefthalf_fill,
            title: l10n.profilePrivacy,
            subtitle: l10n.profilePrivacyDesc,
            onTap: () => context.push(AppRoutePaths.privacy),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _ProfileSection(
        title: l10n.profileSecurity,
        children: [
          _NavRow(
            icon: CupertinoIcons.lock_rotation,
            title: l10n.profileChangePasswordTitle,
            subtitle: l10n.profileChangePasswordDesc,
            onTap: () => _openChangePasswordSheet(context),
          ),
          _NavRow(
            icon: CupertinoIcons.square_arrow_right,
            title: l10n.authLogout,
            subtitle: l10n.authLogoutDesc,
            destructive: true,
            onTap: isSubmitting ? null : () => _logout(context, ref),
          ),
        ],
      ),
    ];

    final hero = _ProfileHero(
      user: user,
      isDesktop: isDesktop,
      onViewPublicProfile: () =>
          context.push(buildPublicProfileLocation(user.id)),
    );

    return CupertinoPageScaffold(
      backgroundColor: context.mc.background,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          if (isDesktop)
            SliverToBoxAdapter(
              child: _ProfilePaneHeader(
                title: l10n.tabProfile,
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _openEditSheet(context, ref, user),
                  child: Icon(
                    CupertinoIcons.pencil_circle,
                    size: 22,
                    color: context.mc.primary,
                  ),
                ),
              ),
            )
          else
            CupertinoSliverNavigationBar(
              largeTitle: Text(l10n.tabProfile),
              backgroundColor: context.mc.background.withValues(alpha: 0.94),
              border: null,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _openEditSheet(context, ref, user),
                child: const Icon(CupertinoIcons.pencil_circle, size: 24),
              ),
            ),
          CupertinoSliverRefreshControl(
            onRefresh: () =>
                ref.read(authControllerProvider.notifier).refreshProfile(),
          ),
          SliverToBoxAdapter(
            child: isDesktop
                // Desktop: one centered column (hero on top, then the
                // settings cards) instead of the old side-by-side two pane.
                ? AppResponsiveCenter(
                    key: const ValueKey('profile-desktop-single-column'),
                    maxWidth: 780,
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        hero,
                        const SizedBox(height: 24),
                        ...sections,
                      ],
                    ),
                  )
                : AppResponsiveCenter(
                    padding: AppResponsive.sliverPagePadding(
                      context,
                      bottom: 32,
                    ),
                    child: AppTwoPane(
                      key: const ValueKey('profile-responsive-two-pane'),
                      secondaryFirstOnWide: true,
                      primary: Column(children: sections),
                      secondary: hero,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context).profileConfirmLogout),
        content: Text(AppLocalizations.of(context).profileConfirmLogoutDesc),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).authLogout),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(authControllerProvider.notifier).logout();
  }

  Future<void> _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    UserDto user,
  ) async {
    await showMcBottomSheet<void>(
      context: context,
      builder: (context) => _ProfileEditSheet(initialUser: user),
    );
  }

  Future<void> _openChangePasswordSheet(BuildContext context) async {
    await showMcBottomSheet<void>(
      context: context,
      builder: (context) => const ChangePasswordSheet(),
    );
  }

  Future<void> _startVerification({
    required BuildContext context,
    required WidgetRef ref,
    required Future<void> Function() sendCode,
    required Future<void> Function(String code) verifyCode,
    required String successMessage,
  }) async {
    final codeController = TextEditingController();

    try {
      await sendCode();
      if (!context.mounted) return;
      await McFeedback.showSuccess(
        context,
        message: AppLocalizations.of(context).authSendCodeSuccess,
      );
    } catch (_) {
      final errorMessage = ref
          .read(authControllerProvider)
          .asData
          ?.value
          .errorMessage;
      if (errorMessage != null && errorMessage.isNotEmpty && context.mounted) {
        await McFeedback.showError(context, message: errorMessage);
      }
      codeController.dispose();
      return;
    }

    if (!context.mounted) {
      codeController.dispose();
      return;
    }

    final shouldVerify = await showMcBottomSheet<bool>(
      context: context,
      builder: (dialogContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(dialogContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context).profileEnterCode,
                style: context.mc.textSection,
              ),
              const SizedBox(height: 16),
              McField.text(
                controller: codeController,
                placeholder: AppLocalizations.of(context).profileEnterCodeHint,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: McButton.secondary(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: McButton.primary(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(
                        AppLocalizations.of(context).profileConfirmVerify,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldVerify != true) {
      codeController.dispose();
      return;
    }

    try {
      await verifyCode(codeController.text.trim());
      if (!context.mounted) return;
      await McFeedback.showSuccess(context, message: successMessage);
    } catch (_) {
      final errorMessage = ref
          .read(authControllerProvider)
          .asData
          ?.value
          .errorMessage;
      if (errorMessage != null && errorMessage.isNotEmpty && context.mounted) {
        await McFeedback.showError(context, message: errorMessage);
      }
    } finally {
      codeController.dispose();
    }
  }

  static String _fallback(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.onViewPublicProfile,
    this.isDesktop = false,
  });

  final UserDto user;
  final VoidCallback onViewPublicProfile;

  /// Desktop keeps a single centered column, so the card gets room for the
  /// name/bio block plus an explicit "public profile" action instead of the
  /// narrow-screen chevron.
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = user.name?.trim().isNotEmpty == true
        ? user.name!.trim()
        : l10n.profileNoNickname;
    final info = user.info?.trim().isNotEmpty == true
        ? user.info!.trim()
        : l10n.profileOwnerLowkey;

    return McCard.elevated(
      padding: const EdgeInsets.all(20),
      onPressed: onViewPublicProfile,
      child: Row(
        children: [
          AppAvatar(
            url: user.avatar,
            name: user.name,
            size: 72,
            radius: 20,
            isCircle: false,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.mc.textSection),
                const SizedBox(height: 4),
                Text(
                  info,
                  style: context.mc.textMuted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 16),
            McButton.secondary(
              onPressed: onViewPublicProfile,
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ),
              child: Text(
                l10n.profilePublicProfile,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: context.mc.secondaryLabel,
            ),
        ],
      ),
    );
  }
}

class _ProfilePaneHeader extends StatelessWidget {
  const _ProfilePaneHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.mc.foreground,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title, style: context.mc.textLabel),
        ),
        McCard.elevated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.destructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? context.mc.destructive
        : McColorManager.generateSoftColor(
            title,
            isDark: CupertinoTheme.of(context).brightness == Brightness.dark,
          );
    return McListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      onTap: onTap,
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: destructive ? context.mc.destructive : context.mc.primary,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        size: 14,
        color: context.mc.secondaryLabel,
      ),
    );
  }
}

class _ThemeModeSection extends ConsumerWidget {
  const _ThemeModeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final currentLocale = ref.watch(localeNotifierProvider);
    final l10n = AppLocalizations.of(context);

    return _ProfileSection(
      title: l10n.profileDisplaySettings,
      children: [
        _NavRow(
          icon: themeMode.icon,
          title: l10n.themeMode,
          subtitle: l10n.themeSubtitle,
          onTap: () => _showThemeModeSheet(context, ref, themeMode),
        ),
        const SizedBox(height: 4),
        _NavRow(
          icon: CupertinoIcons.globe,
          title: l10n.settingsLanguage,
          subtitle: _localeLabel(currentLocale, l10n),
          onTap: () => _showLanguageSheet(context, ref, currentLocale),
        ),
      ],
    );
  }

  String _themeModeLabel(AppThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      AppThemeMode.system => l10n.themeSystem,
      AppThemeMode.light => l10n.themeLight,
      AppThemeMode.dark => l10n.themeDark,
    };
  }

  void _showThemeModeSheet(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode currentMode,
  ) {
    final l10n = AppLocalizations.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(AppLocalizations.of(context).appearanceModeTitle),
        actions: [
          for (final mode in AppThemeMode.values)
            CupertinoActionSheetAction(
              isDefaultAction: mode == currentMode,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                ref.read(themeModeNotifierProvider.notifier).setMode(mode);
              },
              child: _ThemeModeActionLabel(
                mode: mode,
                label: _themeModeLabel(mode, l10n),
                isSelected: mode == currentMode,
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
      ),
    );
  }

  String _localeLabel(Locale? locale, AppLocalizations l10n) {
    if (locale == null) return l10n.followSystem;

    return switch (locale.languageCode) {
      'zh' => l10n.language_zh,
      'en' => l10n.language_en,
      'ja' => l10n.language_ja,
      'ru' => l10n.language_ru,
      'fr' => l10n.language_fr,
      'de' => l10n.language_de,
      'ko' => l10n.language_ko,
      _ => locale.toString(),
    };
  }

  void _showLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    Locale? currentLocale,
  ) {
    final l10n = AppLocalizations.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(l10n.settingsLanguageTitle),
        actions: [
          CupertinoActionSheetAction(
            isDefaultAction: currentLocale == null,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              ref.read(localeNotifierProvider.notifier).setLocale(null);
            },
            child: _LanguageActionLabel(
              label: l10n.followSystem,
              isSelected: currentLocale == null,
            ),
          ),
          for (final locale in supportedLocales)
            CupertinoActionSheetAction(
              isDefaultAction: currentLocale == locale,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                ref.read(localeNotifierProvider.notifier).setLocale(locale);
              },
              child: _LanguageActionLabel(
                label: _localeLabel(locale, l10n),
                isSelected: currentLocale == locale,
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }
}

class _ThemeModeActionLabel extends StatelessWidget {
  const _ThemeModeActionLabel({
    required this.mode,
    required this.label,
    required this.isSelected,
  });

  final AppThemeMode mode;
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? context.mc.primary : context.mc.foreground;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(mode.icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
        const SizedBox(width: 8),
        Opacity(
          opacity: isSelected ? 1 : 0,
          child: Icon(
            CupertinoIcons.check_mark,
            size: 18,
            color: context.mc.primary,
          ),
        ),
      ],
    );
  }
}

class _LanguageActionLabel extends StatelessWidget {
  const _LanguageActionLabel({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? context.mc.primary : context.mc.foreground;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: color)),
        const SizedBox(width: 8),
        Opacity(
          opacity: isSelected ? 1 : 0,
          child: Icon(
            CupertinoIcons.check_mark,
            size: 18,
            color: context.mc.primary,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return McListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(value, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _VerificationRow extends StatelessWidget {
  const _VerificationRow({
    required this.label,
    required this.isVerified,
    required this.isBusy,
    required this.onVerify,
  });

  final String label;
  final bool isVerified;
  final bool isBusy;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return McListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isVerified
            ? AppLocalizations.of(context).profileEmailVerified
            : AppLocalizations.of(context).profileEmailNotVerified,
      ),
      trailing: isVerified
          ? Icon(
              CupertinoIcons.check_mark_circled_solid,
              color: context.mc.success,
              size: 20,
            )
          : CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: isBusy ? null : onVerify,
              child: Text(
                AppLocalizations.of(context).profileVerifyEmail,
                style: TextStyle(
                  color: context.mc.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

class _ProfileEditSheet extends ConsumerStatefulWidget {
  const _ProfileEditSheet({required this.initialUser});

  final UserDto initialUser;

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _infoController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialUser.name ?? '',
    );
    _infoController = TextEditingController(
      text: widget.initialUser.info ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  void _generateRandomAvatar() {
    ref
        .read(profileEditControllerProvider(widget.initialUser).notifier)
        .generateRandomAvatar();
  }

  Future<void> _pickFromGallery() async {
    await ref
        .read(profileEditControllerProvider(widget.initialUser).notifier)
        .pickFromGallery();
  }

  Future<void> _takePhoto() async {
    final granted = await requestCameraPermission();
    if (!granted) {
      if (!mounted) return;
      await McFeedback.showError(
        context,
        message: AppLocalizations.of(context).permissionCameraNeeded,
      );
      return;
    }

    await ref
        .read(profileEditControllerProvider(widget.initialUser).notifier)
        .takePhoto();
  }

  void _showAvatarOptions() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(AppLocalizations.of(context).authSelectAvatar),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _generateRandomAvatar();
            },
            child: Text(AppLocalizations.of(context).authRandomAvatar),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickFromGallery();
            },
            child: Text(AppLocalizations.of(context).authPickFromGallery),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _takePhoto();
            },
            child: Text(AppLocalizations.of(context).authTakePhoto),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppLocalizations.of(context).cancel),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    try {
      await ref
          .read(profileEditControllerProvider(widget.initialUser).notifier)
          .submit(name: _nameController.text, info: _infoController.text);
      if (!mounted) return;
      await McFeedback.showSuccess(
        context,
        message: AppLocalizations.of(context).profileUpdated,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ProfileAvatarUploadException {
      if (mounted) {
        await McFeedback.showError(
          context,
          message: AppLocalizations.of(context).errorAvatarUploadFailed,
        );
      }
    } catch (_) {
      final errorMessage = ref
          .read(authControllerProvider)
          .asData
          ?.value
          .errorMessage;
      if (mounted) {
        await McFeedback.showError(
          context,
          message: errorMessage?.isNotEmpty == true
              ? errorMessage!
              : AppLocalizations.of(context).profileUpdateFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider).asData?.value;
    final editState = ref.watch(
      profileEditControllerProvider(widget.initialUser),
    );
    final isSubmitting =
        editState.isSaving || (authState?.isSubmitting ?? false);

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
            Text(l10n.profileEditProfile, style: context.mc.textSection),
            const SizedBox(height: 20),

            // Avatar picker
            Center(
              child: GestureDetector(
                onTap: isSubmitting ? null : _showAvatarOptions,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _AvatarPreview(
                      file: editState.avatarFile,
                      url: editState.avatarUrl,
                      name: _nameController.text,
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.mc.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.camera,
                          size: 16,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.profileClickToChangeAvatar,
                style: context.mc.textLabel.copyWith(fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),

            McField.text(
              controller: _nameController,
              placeholder: l10n.profileNickname,
              maxLength: DtoLimits.userNameMax,
              validator: (v) => optionalMaxValidator(
                v,
                max: DtoLimits.userNameMax,
                maxMessage: l10n.validatorNameTooLong(DtoLimits.userNameMax),
              ),
            ),
            const SizedBox(height: 12),
            McField.text(
              controller: _infoController,
              placeholder: l10n.profileBioPlaceholder,
              maxLines: 3,
              maxLength: DtoLimits.userInfoMax,
              validator: (v) => optionalMaxValidator(
                v,
                max: DtoLimits.userInfoMax,
                maxMessage: l10n.profileBioTooLong(DtoLimits.userInfoMax),
              ),
            ),
            const SizedBox(height: 24),
            McButton.primary(
              onPressed: isSubmitting ? null : _submit,
              child: Text(
                isSubmitting ? l10n.profileSaving : l10n.profileSaveChanges,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.file, required this.url, this.name});

  final XFile? file;
  final String url;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final localFile = file;
    if (localFile == null) {
      return AppAvatar(url: url, name: name, size: 88, radius: 44);
    }

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: context.mc.secondary,
        borderRadius: BorderRadius.circular(44),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.file(File(localFile.path), fit: BoxFit.cover),
    );
  }
}
