import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/states.dart';
import '../../data/models/account.dart';
import '../../state/account_controllers.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';

/// Loyalty points balance and movements. Points are a backend ledger; there is
/// no client-side earning or redemption rule.
class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final loyalty = ref.watch(loyaltyProvider);

    return AppScaffold(
      header: SimpleHeader(title: l10n.loyalty, onBack: () => context.pop()),
      onRefresh: signedIn ? () => _refresh(ref) : null,
      body: !signedIn
          ? EmptyState(
              title: l10n.loyalty,
              message: l10n.notAuthorized,
              icon: Icons.stars_outlined,
              actionLabel: l10n.signIn,
              onAction: () => context.push('/login?next=/account/loyalty'),
            )
          : AsyncView(
              value: loyalty,
              onRetry: () => _refresh(ref),
              builder: (summary) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  _PointsCard(points: summary.points),
                  const SizedBox(height: AppSpacing.md),
                  _notice(l10n),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.loyaltyHistory, style: AppTypography.headlineSm),
                  const SizedBox(height: AppSpacing.md),
                  if (summary.entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: EmptyState(
                        title: l10n.noLoyaltyEntries,
                        icon: Icons.stars_outlined,
                      ),
                    )
                  else
                    for (final entry in summary.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _EntryCard(entry: entry),
                      ),
                ],
              ),
            ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(loyaltyProvider);
    try {
      await ref.read(loyaltyProvider.future);
    } catch (_) {
      // The AsyncView shows the error state.
    }
  }

  Widget _notice(L10n l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.tertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.loyaltyInfo,
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.tertiary, AppColors.tertiaryContainer],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.stars_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.loyalty,
                  style: AppTypography.labelLg.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$points',
                style: AppTypography.headlineXlMobile.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.points,
                style: AppTypography.labelLg.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final LoyaltyEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final positive = entry.pointsDelta >= 0;
    final color = positive ? AppColors.tertiary : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              positive ? Icons.add_circle_outline : Icons.remove_circle_outline,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.reason.isEmpty
                      ? (positive ? l10n.pointsEarned : l10n.pointsRedeemed)
                      : entry.reason,
                  style: AppTypography.labelLg,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  [
                    if (entry.orderId != null) entry.orderId!,
                    Fmt.dateTime(entry.createdAt),
                  ].join(' • '),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            positive ? '+${entry.pointsDelta}' : '${entry.pointsDelta}',
            style: AppTypography.labelLg.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
