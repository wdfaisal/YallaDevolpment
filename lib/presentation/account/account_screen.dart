import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/env.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/states.dart';
import '../../data/models/customer.dart';
import '../../state/account_controllers.dart';
import '../../state/home_controller.dart';
import '../../state/language_controller.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';
import '../shared/sheets.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final session = ref.watch(sessionProvider);
    return AppScaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          _header(context, ref, l10n),
          const SizedBox(height: AppSpacing.sm),
          session.when(
            skipLoadingOnRefresh: true,
            data: (profile) => profile == null
                ? _guest(context, l10n)
                : _profile(context, ref, l10n, profile),
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: LoadingState(),
            ),
            error: (error, _) => ErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(sessionProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, L10n l10n) {
    final unread = ref.watch(unreadNotificationsProvider);
    final signedIn = ref.watch(isSignedInProvider);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.surfaceContainerLowest,
      child: Row(
        children: [
          Expanded(
            child: Text(l10n.account, style: AppTypography.headlineSm),
          ),
          if (signedIn)
            HeaderIconButton(
              icon: Icons.notifications_active_outlined,
              tooltip: l10n.notifications,
              badge: unread,
              onTap: () => context.push('/account/notifications'),
            ),
          const SizedBox(width: AppSpacing.xs),
          HeaderIconButton(
            icon: Icons.settings_outlined,
            tooltip: l10n.settings,
            onTap: () => context.push('/account/settings'),
          ),
        ],
      ),
    );
  }

  Widget _guest(BuildContext context, L10n l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [AppColors.primary, AppColors.primaryContainer],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person_outline, size: 34, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.guest,
              style: AppTypography.headlineSm.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.loginSubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () => context.push('/login'),
                child: Text(l10n.signIn),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profile(
    BuildContext context,
    WidgetRef ref,
    L10n l10n,
    CustomerProfile profile,
  ) {
    final wallet = ref.watch(walletProvider);
    final loyalty = ref.watch(loyaltyProvider);
    final offers = ref.watch(homeProvider).valueOrNull?.offers.length ?? 0;
    final arabic = l10n.isArabic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.orangeTintSubtle,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: AppColors.borderMuted),
                ),
                clipBehavior: Clip.antiAlias,
                child: profile.avatarUrl != null
                    ? AppImage(url: profile.avatarUrl, borderRadius: BorderRadius.zero)
                    : Center(
                        child: Text(
                          profile.initials.isEmpty ? '?' : profile.initials,
                          style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name.isEmpty ? l10n.guest : profile.name,
                      style: AppTypography.headlineSm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.phone,
                      style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.email != null && profile.email!.isNotEmpty)
                      Text(
                        profile.email!,
                        style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.memberSince} ${Fmt.date(profile.memberSince)} · '
                      '${profile.orderCount} ${l10n.orderCount}',
                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: l10n.editProfile,
                onPressed: () => context.push('/account/profile'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: l10n.wallet,
                  value: wallet.when(
                    data: (w) => Fmt.money(w.availableMinor, currency: w.currency),
                    loading: () => '—',
                    error: (_, __) => '—',
                  ),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                  onTap: () => context.push('/account/wallet'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryCard(
                  label: l10n.loyalty,
                  value: loyalty.when(
                    data: (l) => '${l.points} ${l10n.points}',
                    loading: () => '—',
                    error: (_, __) => '—',
                  ),
                  icon: Icons.stars_outlined,
                  color: AppColors.tertiary,
                  onTap: () => context.push('/account/loyalty'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryCard(
                  label: l10n.offers,
                  value: '$offers',
                  icon: Icons.local_activity_outlined,
                  color: AppColors.warning,
                  onTap: () => context.go('/'),
                ),
              ),
            ],
          ),
        ),
        _group(l10n.ordersAndPayments, [
          _MenuTile(
            icon: Icons.location_on_outlined,
            color: AppColors.primary,
            title: l10n.addresses,
            subtitle: l10n.addressesSubtitle,
            onTap: () => context.push('/account/addresses'),
          ),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            color: AppColors.tertiary,
            title: l10n.myOrders,
            subtitle: l10n.ordersSubtitle,
            onTap: () => context.go('/orders'),
          ),
          _MenuTile(
            icon: Icons.stars_outlined,
            color: AppColors.warning,
            title: l10n.loyalty,
            subtitle: l10n.loyaltySubtitle,
            onTap: () => context.push('/account/loyalty'),
          ),
          _MenuTile(
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.primaryContainer,
            title: l10n.wallet,
            subtitle: l10n.walletSubtitle,
            onTap: () => context.push('/account/wallet'),
          ),
        ]),
        _group(l10n.preferences, [
          _MenuTile(
            icon: Icons.notifications_active_outlined,
            color: AppColors.primary,
            title: l10n.notifications,
            subtitle: l10n.notificationsSubtitle,
            onTap: () => context.push('/account/notifications'),
          ),
          _MenuTile(
            icon: Icons.language,
            color: AppColors.tertiary,
            title: l10n.language,
            subtitle: arabic ? l10n.arabic : l10n.english,
            trailing: arabic ? l10n.english : l10n.arabic,
            onTap: () async {
              final next = arabic ? 'en' : 'ar';
              await ref.read(languageProvider.notifier).setLanguage(next);
              if (ref.read(isSignedInProvider)) {
                try {
                  await ref.read(sessionProvider.notifier).updateProfile(language: next);
                } catch (_) {
                  // The local preference still applies when the profile call fails.
                }
              }
            },
          ),
          _MenuTile(
            icon: Icons.settings_outlined,
            color: AppColors.secondary,
            title: l10n.settings,
            subtitle: l10n.settingsSubtitle,
            onTap: () => context.push('/account/settings'),
          ),
        ]),
        _group(l10n.supportAndInfo, [
          _MenuTile(
            icon: Icons.support_agent,
            color: AppColors.tertiary,
            title: l10n.support,
            subtitle: l10n.supportSubtitle,
            onTap: () => context.push('/account/support'),
          ),
          _MenuTile(
            icon: Icons.info_outline,
            color: AppColors.secondary,
            title: l10n.about,
            subtitle: 'v${Env.appVersion}',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: l10n.appName,
              applicationVersion: Env.appVersion,
            ),
          ),
          _MenuTile(
            icon: Icons.share_outlined,
            color: AppColors.primaryContainer,
            title: l10n.share,
            subtitle: l10n.shareAppSubtitle,
            onTap: () => Share.share(
              '${l10n.appName} — ${l10n.shareAppMessage}',
              subject: l10n.appName,
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.errorContainer),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(l10n.signOut),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: l10n.signOut,
                  message: l10n.signOutConfirm,
                );
                if (!confirmed) return;
                await ref.read(sessionProvider.notifier).signOut();
                if (context.mounted) context.go('/');
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _group(String title, List<Widget> tiles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4, right: 4),
            child: Text(
              title,
              style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
            ),
          ),
          Container(
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
                  if (i > 0) const Divider(height: 1, color: AppColors.surfaceContainerLow),
                  tiles[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.surfaceContainerHigh),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailing;

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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, size: 20, color: color),
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
                    style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
              ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_left, size: 20, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}
