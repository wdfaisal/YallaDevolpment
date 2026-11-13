import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/states.dart';
import '../../state/address_controller.dart';
import '../../state/session_controller.dart';

/// Bottom sheet used everywhere an address has to be chosen. Only real saved
/// addresses are listed; guests are routed to sign in.
Future<void> showAddressPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _AddressPickerSheet(),
  );
}

class _AddressPickerSheet extends ConsumerWidget {
  const _AddressPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final selection = ref.watch(addressesProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.deliveryAddress, style: AppTypography.headlineSm),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.close,
                  ),
                ],
              ),
            ),
            if (!signedIn)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      l10n.addAddressToSeeNearby,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/login?next=/account/addresses');
                      },
                      child: Text(l10n.signIn),
                    ),
                  ],
                ),
              )
            else
              AsyncView(
                value: selection,
                loading: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: LoadingState(),
                ),
                builder: (data) {
                  if (data.addresses.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Text(
                            l10n.noAddresses,
                            style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.push('/account/addresses/new');
                            },
                            icon: const Icon(Icons.add_location_alt_outlined),
                            label: Text(l10n.addAddress),
                          ),
                        ],
                      ),
                    );
                  }
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: data.addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final address = data.addresses[index];
                        final selected = address.id == data.selected?.id;
                        return InkWell(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          onTap: () {
                            ref.read(addressesProvider.notifier).select(address.id);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.orangeTintSubtle
                                  : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.surfaceContainer,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  address.isDefault ? Icons.home : Icons.location_on_outlined,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              address.label,
                                              style: AppTypography.labelLg,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (address.isDefault) ...[
                                            const SizedBox(width: AppSpacing.sm),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.orangeTintSoft,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                l10n.defaultAddress,
                                                style: AppTypography.labelSm.copyWith(
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        address.address,
                                        style: AppTypography.bodySm.copyWith(
                                          color: AppColors.secondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(Icons.check_circle, color: AppColors.primary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            if (signedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push('/account/addresses/new');
                        },
                        icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                        label: Text(l10n.addAddress),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push('/account/addresses');
                        },
                        child: Text(l10n.addresses),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog shared by destructive actions.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = true,
}) async {
  final l10n = L10n.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel ?? l10n.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Small rounded choice chip used by filters and forms.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.orangeTintSubtle : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceContainer,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? AppColors.primary : AppColors.secondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: selected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
