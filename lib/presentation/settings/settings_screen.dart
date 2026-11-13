import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../state/language_controller.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';
import '../shared/sheets.dart';

/// App settings: language, notification entry point, privacy and account.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final profile = ref.watch(sessionProvider).valueOrNull;
    final language = ref.watch(languageProvider);

    return AppScaffold(
      header: SimpleHeader(title: l10n.settings, onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          _section(l10n.appLanguage),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppChoiceChip(
                    label: l10n.arabic,
                    icon: Icons.translate,
                    selected: language == 'ar',
                    onTap: () => _setLanguage(ref, 'ar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppChoiceChip(
                    label: l10n.english,
                    icon: Icons.language,
                    selected: language == 'en',
                    onTap: () => _setLanguage(ref, 'en'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _section(l10n.preferences),
          _group([
            _Tile(
              icon: Icons.notifications_active_outlined,
              title: l10n.notifications,
              subtitle: l10n.notificationsSubtitle,
              onTap: signedIn
                  ? () => context.push('/account/notifications')
                  : null,
            ),
            _Tile(
              icon: Icons.support_agent,
              title: l10n.support,
              subtitle: l10n.supportSubtitle,
              onTap: () => context.push('/account/support'),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _section(l10n.privacy),
          _group([
            _Tile(
              icon: Icons.lock_outline,
              title: l10n.privacy,
              subtitle: l10n.privacyNotice,
              onTap: () => _showPrivacy(context, l10n),
            ),
            _Tile(
              icon: Icons.info_outline,
              title: l10n.appVersion,
              subtitle: 'v${Env.appVersion}',
            ),
            _Tile(
              icon: Icons.verified_user_outlined,
              title: l10n.accountStatus,
              subtitle: profile == null
                  ? l10n.guest
                  : (profile.isSuspended
                      ? l10n.statusSuspended
                      : l10n.statusActive),
            ),
          ]),
          if (signedIn) ...[
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.errorContainer),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(l10n.signOut),
                  onPressed: () => _signOut(context, ref, l10n),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _setLanguage(WidgetRef ref, String code) async {
    await ref.read(languageProvider.notifier).setLanguage(code);
    if (ref.read(isSignedInProvider)) {
      try {
        await ref.read(sessionProvider.notifier).updateProfile(language: code);
      } catch (_) {
        // The local preference still applies when the profile call fails.
      }
    }
  }

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref,
    L10n l10n,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.signOut,
      message: l10n.signOutConfirm,
    );
    if (!confirmed) return;
    await ref.read(sessionProvider.notifier).signOut();
    if (context.mounted) context.go('/');
  }

  Future<void> _showPrivacy(BuildContext context, L10n l10n) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.privacy, style: AppTypography.headlineSm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.privacyNotice, style: AppTypography.bodyMd),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.notificationsManagedBySystem,
              style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
      ),
    );
  }

  Widget _group(List<Widget> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.surfaceContainerHigh),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: AppColors.surfaceContainerLow),
              tiles[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelLg),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.secondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_left,
                size: 20,
                color: AppColors.secondary,
              ),
          ],
        ),
      ),
    );
  }
}
