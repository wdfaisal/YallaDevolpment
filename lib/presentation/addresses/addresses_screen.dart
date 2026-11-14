import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/customer.dart';
import '../../state/address_controller.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';
import '../shared/sheets.dart';

/// Saved delivery addresses. Tapping a card selects it for ordering; the
/// default flag and coverage zone are owned by the backend.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final addresses = ref.watch(addressesProvider);

    return AppScaffold(
      header: SimpleHeader(
        title: l10n.addresses,
        onBack: () => context.pop(),
        actions: [
          if (signedIn)
            HeaderIconButton(
              icon: Icons.add_location_alt_outlined,
              tooltip: l10n.addNewAddress,
              onTap: () => context.push('/account/addresses/new'),
            ),
        ],
      ),
      onRefresh:
          signedIn ? () => ref.read(addressesProvider.notifier).reload() : null,
      body: !signedIn
          ? EmptyState(
              title: l10n.noAddresses,
              message: l10n.notAuthorized,
              icon: Icons.location_on_outlined,
              actionLabel: l10n.signIn,
              onAction: () => context.push('/login?next=/account/addresses'),
            )
          : AsyncView(
              value: addresses,
              onRetry: () => ref.read(addressesProvider.notifier).reload(),
              builder: (selection) {
                if (selection.addresses.isEmpty) {
                  return EmptyState(
                    title: l10n.noAddresses,
                    icon: Icons.location_on_outlined,
                    actionLabel: l10n.addAddress,
                    onAction: () => context.push('/account/addresses/new'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: selection.addresses.length + 1,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    if (index == selection.addresses.length) {
                      return OutlinedButton.icon(
                        onPressed: () => context.push('/account/addresses/new'),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.addNewAddress),
                      );
                    }
                    final address = selection.addresses[index];
                    return _AddressCard(
                      address: address,
                      selected: selection.selectedId == address.id,
                      onTap: () {
                        ref.read(addressesProvider.notifier).select(address.id);
                        showAppSnack(context, l10n.useAddress);
                      },
                      onEdit: () =>
                          context.push('/account/addresses/${address.id}/edit'),
                      onDelete: () => _delete(context, ref, l10n, address),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    L10n l10n,
    CustomerAddressRecord address,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteAddress,
      message: l10n.deleteAddressConfirm,
      confirmLabel: l10n.delete,
    );
    if (!confirmed) return;
    try {
      await ref.read(addressesProvider.notifier).remove(address.id);
      if (context.mounted) showAppSnack(context, l10n.addressDeleted);
    } catch (error) {
      if (!context.mounted) return;
      showAppSnack(
        context,
        error is ApiException ? error.message : l10n.somethingWentWrong,
        isError: true,
      );
    }
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomerAddressRecord address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color:
                selected ? AppColors.primary : AppColors.surfaceContainerHigh,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.orangeTintSubtle,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
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
                              style: AppTypography.labelLg.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _Badge(label: l10n.defaultAddress),
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
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
            if (address.instructions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.edit_note,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      address.instructions,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.secondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (address.zoneId != null)
                  _Meta(
                    icon: Icons.map_outlined,
                    label: '${l10n.zone}: ${address.zoneId}',
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l10n.edit),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(l10n.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.orangeTintSubtle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}
