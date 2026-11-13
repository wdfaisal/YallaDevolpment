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
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/models/customer.dart';
import '../../state/account_controllers.dart';
import '../../state/address_controller.dart';
import '../../state/home_controller.dart';
import '../../state/language_controller.dart';
import '../../state/session_controller.dart';
import '../shared/sheets.dart';
import 'widgets/account_footer.dart';
import 'widgets/account_header.dart';
import 'widgets/account_menu_section.dart';
import 'widgets/account_profile_header.dart';
import 'widgets/account_summary_cards.dart';

/// Account tab rebuilt from the Stitch profile design. Every value comes from
/// the live backend or the local session; nothing is invented.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final session = ref.watch(sessionProvider);
    return AppScaffold(
      header: AccountHeader(
        onShare: () => Share.share(
          '${l10n.appName} — ${l10n.shareAppMessage}',
          subject: l10n.appName,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          session.when(
            skipLoadingOnRefresh: true,
            data: (profile) => profile == null
                ? _GuestAccount(l10n: l10n)
                : _SignedInAccount(profile: profile),
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xxxl),
              child: LoadingState(),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(sessionProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _versionLabel(L10n l10n) =>
    '${l10n.appVersion} ${Env.appVersion} (YallaTalabat v${Env.appVersion})';

Future<void> _showInfoDialog(
  BuildContext context,
  String title,
  String message,
) {
  final l10n = L10n.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}

class _GuestAccount extends StatelessWidget {
  const _GuestAccount({required this.l10n});

  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.profileBorder),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.profileCardShadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.profileAccentTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 36,
                    color: AppColors.profileAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.guest,
                  style: AppTypography.headlineSm.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.profileHeading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 12,
                    color: AppColors.profileSecondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.profileAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => context.push('/login'),
                    child: Text(
                      l10n.signIn,
                      style: AppTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AccountFooter(versionLabel: _versionLabel(l10n)),
      ],
    );
  }
}

class _SignedInAccount extends ConsumerWidget {
  const _SignedInAccount({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final arabic = l10n.isArabic;
    final wallet = ref.watch(walletProvider).valueOrNull;
    final loyalty = ref.watch(loyaltyProvider).valueOrNull;
    final offers = ref.watch(homeProvider).valueOrNull?.offers.length ?? 0;
    final addresses =
        ref.watch(addressesProvider).valueOrNull?.addresses.length ?? 0;
    final notificationsOn = ref.watch(notificationsEnabledProvider);
    final points = loyalty?.points ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountProfileHeader(
          name: profile.name.isEmpty ? l10n.guest : profile.name,
          phone: profile.phone,
          email: profile.email,
          initials: profile.initials,
          avatarUrl: profile.avatarUrl,
          changePhotoTooltip: l10n.changePhoto,
          onEdit: () => context.push('/account/profile'),
        ),
        AccountSummaryCards(
          cards: [
            AccountSummaryCardData(
              label: l10n.walletCardTitle,
              value: wallet == null ? '—' : Fmt.money(wallet.availableMinor),
              unit: l10n.currencyDefault,
              icon: Icons.account_balance_wallet,
              iconColor: AppColors.profileAccent,
              actionLabel: l10n.topUpBalance,
              accentAction: true,
              onAction: () => context.push('/account/wallet'),
            ),
            AccountSummaryCardData(
              label: l10n.rewardPoints,
              value: loyalty == null ? '—' : '$points',
              unit: l10n.points,
              icon: Icons.loyalty,
              iconColor: AppColors.profileEmerald,
              actionLabel: l10n.redeem,
              onAction: () => context.push('/account/loyalty'),
            ),
            AccountSummaryCardData(
              label: l10n.offers,
              value: '$offers',
              unit: l10n.offersUnit,
              icon: Icons.local_activity_outlined,
              iconColor: AppColors.profileAmber,
              actionLabel: l10n.browse,
              onAction: () => context.go('/'),
            ),
          ],
        ),
        AccountMenuSection(
          title: l10n.manageOrdersAndPayments,
          children: [
            AccountMenuTile(
              icon: Icons.location_on,
              iconColor: AppColors.profileAccent,
              iconBackground: AppColors.profileAccentTint,
              title: l10n.savedAddresses,
              subtitle: addresses == 0
                  ? l10n.noAddresses
                  : l10n.savedAddressesSubtitle(addresses),
              trailing: addresses == 0
                  ? null
                  : AccountCountBadge(label: '$addresses'),
              onTap: () => context.push('/account/addresses'),
            ),
            AccountMenuTile(
              icon: Icons.credit_card,
              iconColor: AppColors.profileBlue,
              iconBackground: AppColors.profileBlueTint,
              title: l10n.paymentMethods,
              subtitle: l10n.paymentMethodsSubtitle,
              onTap: () => _showInfoDialog(
                context,
                l10n.paymentMethods,
                l10n.paymentMethodsInfo,
              ),
            ),
            AccountMenuTile(
              icon: Icons.receipt_long,
              iconColor: AppColors.profilePurple,
              iconBackground: AppColors.profilePurpleTint,
              title: l10n.orderHistory,
              subtitle: l10n.orderHistorySubtitle,
              onTap: () => context.go('/orders'),
            ),
            AccountMenuTile(
              icon: Icons.stars,
              iconColor: AppColors.profileAmber,
              iconBackground: AppColors.profileAmberTint,
              title: l10n.loyaltyProgram,
              subtitle: l10n.loyaltyProgramSubtitle,
              titleBadge: AccountCountBadge(label: '$points ${l10n.points}'),
              onTap: () => context.push('/account/loyalty'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AccountMenuSection(
          title: l10n.preferencesAndSettings,
          children: [
            AccountMenuTile(
              icon: Icons.notifications_active,
              iconColor: AppColors.profileOrange,
              iconBackground: AppColors.profileOrangeTint,
              title: l10n.notificationSettings,
              subtitle: l10n.notificationSettingsSubtitle,
              showChevron: false,
              trailing: AccountSwitch(
                value: notificationsOn,
                semanticLabel: l10n.notificationSettings,
                onChanged: (value) async {
                  await ref
                      .read(notificationsEnabledProvider.notifier)
                      .setEnabled(value);
                  if (!context.mounted) return;
                  showAppSnack(
                    context,
                    value
                        ? l10n.notificationsEnabledToast
                        : l10n.notificationsDisabledToast,
                  );
                },
              ),
            ),
            AccountMenuTile(
              icon: Icons.tune,
              iconColor: AppColors.profileTeal,
              iconBackground: AppColors.profileTealTint,
              title: l10n.languageAndAppearance,
              subtitle:
                  '${arabic ? l10n.arabic : l10n.english} • ${l10n.lightTheme}',
              trailing: Text(
                arabic ? l10n.arabic : l10n.english,
                style: AppTypography.labelMd.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.profileSecondaryText,
                ),
              ),
              onTap: () async {
                final next = arabic ? 'en' : 'ar';
                await ref.read(languageProvider.notifier).setLanguage(next);
                if (ref.read(isSignedInProvider)) {
                  try {
                    await ref
                        .read(sessionProvider.notifier)
                        .updateProfile(language: next);
                  } catch (_) {
                    // The local preference still applies when the call fails.
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AccountMenuSection(
          title: l10n.supportAndInfo,
          children: [
            AccountMenuTile(
              icon: Icons.support_agent,
              iconColor: AppColors.profileEmerald,
              iconBackground: AppColors.profileEmeraldTint,
              title: l10n.helpAndSupport,
              subtitle: l10n.supportSubtitle,
              titleBadge: const AccountStatusDot(),
              trailing: AccountStatusBadge(label: l10n.availableNow),
              onTap: () => context.push('/account/support'),
            ),
            AccountMenuTile(
              icon: Icons.description,
              iconColor: AppColors.profileGray,
              iconBackground: AppColors.profileGrayTint,
              title: l10n.termsAndPrivacy,
              subtitle: l10n.termsAndPrivacySubtitle,
              onTap: () => _showInfoDialog(
                context,
                l10n.termsAndPrivacy,
                l10n.termsNotice,
              ),
            ),
          ],
        ),
        AccountFooter(
          versionLabel: _versionLabel(l10n),
          onSignOut: () async {
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
      ],
    );
  }
}
