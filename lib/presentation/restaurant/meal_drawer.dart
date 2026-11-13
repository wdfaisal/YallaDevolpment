import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/catalog.dart';
import '../../state/address_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';

/// Opens the meal details drawer. Pass a loaded [item] when the menu already
/// has it, or a [menuItemId] to fetch it (deep links, banners, favorites).
Future<void> showMealDrawer(
  BuildContext context, {
  CatalogMenuItem? item,
  String? menuItemId,
  bool restaurantOpen = true,
}) {
  assert(item != null || menuItemId != null);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MealSheet(
      item: item,
      menuItemId: menuItemId,
      restaurantOpen: restaurantOpen,
    ),
  );
}

class _MealSheet extends ConsumerStatefulWidget {
  const _MealSheet({
    this.item,
    this.menuItemId,
    required this.restaurantOpen,
  });

  final CatalogMenuItem? item;
  final String? menuItemId;
  final bool restaurantOpen;

  @override
  ConsumerState<_MealSheet> createState() => _MealSheetState();
}

class _MealSheetState extends ConsumerState<_MealSheet> {
  CatalogMenuItem? _item;
  Object? _error;
  bool _loading = false;
  bool _adding = false;
  int _quantity = 1;
  final Map<String, Set<String>> _selected = {};
  final TextEditingController _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    if (_item != null) {
      _applyDefaults(_item!);
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final address = ref.read(selectedAddressProvider);
      final item = await ref.read(catalogRepositoryProvider).menuItem(
            widget.menuItemId!,
            addressId: address?.id,
            lat: address?.lat,
            lng: address?.lng,
          );
      if (!mounted) return;
      setState(() {
        _item = item;
        _loading = false;
      });
      _applyDefaults(item);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _applyDefaults(CatalogMenuItem item) {
    for (final group in item.optionGroups) {
      final defaults = group.options
          .where((o) => o.isDefault && o.available)
          .map((o) => o.id)
          .take(group.isSingle ? 1 : group.maxSelect)
          .toSet();
      if (defaults.isNotEmpty) _selected[group.id] = defaults;
    }
  }

  int get _unitMinor {
    final item = _item;
    if (item == null) return 0;
    var total = item.priceMinor;
    for (final group in item.optionGroups) {
      final chosen = _selected[group.id] ?? const <String>{};
      for (final option in group.options) {
        if (chosen.contains(option.id)) total += option.priceDeltaMinor;
      }
    }
    return total;
  }

  List<String> get _optionIds => _selected.values.expand((e) => e).toList(growable: false);

  void _toggle(MenuOptionGroup group, MenuOption option) {
    if (!option.available) return;
    final current = _selected.putIfAbsent(group.id, () => <String>{});
    setState(() {
      if (group.isSingle) {
        current
          ..clear()
          ..add(option.id);
      } else if (current.contains(option.id)) {
        current.remove(option.id);
      } else if (current.length < group.maxSelect) {
        current.add(option.id);
      }
    });
  }

  String? _validationError(L10n l10n) {
    final item = _item;
    if (item == null) return null;
    for (final group in item.optionGroups) {
      final count = _selected[group.id]?.length ?? 0;
      if (count < group.effectiveMin) return l10n.selectRequiredOptions;
    }
    return null;
  }

  Future<void> _add() async {
    final item = _item;
    if (item == null || _adding) return;
    final l10n = L10n.of(context);
    if (!widget.restaurantOpen) {
      showAppSnack(context, l10n.restaurantClosedNotice, isError: true);
      return;
    }
    final validation = _validationError(l10n);
    if (validation != null) {
      showAppSnack(context, validation, isError: true);
      return;
    }
    if (ref.read(sessionProvider).valueOrNull == null) {
      Navigator.of(context).pop();
      context.push('/login');
      return;
    }
    setState(() => _adding = true);
    try {
      await ref.read(cartProvider.notifier).addItem(
            menuItemId: item.id,
            quantity: _quantity,
            optionIds: _optionIds,
            notes: _notes.text.trim(),
          );
      if (!mounted) return;
      showAppSnack(context, l10n.addedToCart);
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _adding = false);
      showAppSnack(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _adding = false);
      showAppSnack(context, l10n.somethingWentWrong, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: media.size.height * 0.92,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          boxShadow: AppColors.sheetShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
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
            Expanded(child: _content(l10n)),
            if (_item != null) _addBar(l10n),
          ],
        ),
      ),
    );
  }

  Widget _content(L10n l10n) {
    if (_loading) {
      return const LoadingState(message: null);
    }
    if (_error != null) {
      return ErrorState(
        message: _error.toString(),
        onRetry: _load,
      );
    }
    final item = _item;
    if (item == null) return const SizedBox.shrink();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          children: [
            SizedBox(
              height: 240,
              width: double.infinity,
              child: AppImage(url: item.imageUrl, borderRadius: BorderRadius.zero),
            ),
            PositionedDirectional(
              top: AppSpacing.sm,
              start: AppSpacing.sm,
              child: Material(
                color: Colors.black.withValues(alpha: 0.4),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Share.share(
                    '${item.name} — ${item.restaurantName}\n'
                    '${Fmt.money(item.priceMinor, currency: l10n.currencyDefault)}',
                    subject: item.name,
                  ),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.share_outlined, color: Colors.white, size: 19),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: AppSpacing.sm,
              end: AppSpacing.sm,
              child: Material(
                color: Colors.black.withValues(alpha: 0.4),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!item.available)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    l10n.itemUnavailable,
                    style: AppTypography.labelMd.copyWith(color: AppColors.error),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(item.name, style: AppTypography.headlineMd),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    Fmt.money(item.priceMinor, currency: l10n.currencyDefault),
                    style: AppTypography.headlineSm.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.description,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: 4,
                children: [
                  if (item.calories != null)
                    _Chip(icon: Icons.local_fire_department_outlined, label: '${item.calories} kcal'),
                  if (item.prepMinutes > 0)
                    _Chip(icon: Icons.schedule, label: '${item.prepMinutes} ${l10n.minuteShort}'),
                  if (item.restaurantName.isNotEmpty)
                    _Chip(icon: Icons.storefront_outlined, label: item.restaurantName),
                ],
              ),
            ],
          ),
        ),
        for (final group in item.optionGroups) _optionGroup(group, l10n),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.specialInstructions, style: AppTypography.labelLg),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notes,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(hintText: l10n.notesHint, counterText: ''),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: Text(l10n.quantity, style: AppTypography.labelLg)),
                  QuantityStepper(
                    value: _quantity,
                    onChanged: (value) => setState(() => _quantity = value),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _optionGroup(MenuOptionGroup group, L10n l10n) {
    final chosen = _selected[group.id] ?? const <String>{};
    final hint = group.isSingle
        ? (group.effectiveMin > 0 ? l10n.chooseOne : l10n.optional)
        : '${l10n.chooseUpTo} ${group.maxSelect}';
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(group.name(l10n.isArabic), style: AppTypography.labelLg),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: group.effectiveMin > 0
                      ? AppColors.orangeTintSoft
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  group.effectiveMin > 0 ? l10n.required : l10n.optional,
                  style: AppTypography.labelSm.copyWith(
                    color: group.effectiveMin > 0 ? AppColors.primary : AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(hint, style: AppTypography.bodySm.copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSpacing.sm),
          for (final option in group.options)
            _OptionRow(
              option: option,
              selected: chosen.contains(option.id),
              single: group.isSingle,
              onTap: () => _toggle(group, option),
            ),
        ],
      ),
    );
  }

  Widget _addBar(L10n l10n) {
    final item = _item!;
    final total = _unitMinor * _quantity;
    final enabled = item.available && !_adding;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
        boxShadow: AppColors.sheetShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.total, style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
                Text(
                  Fmt.money(total, currency: l10n.currencyDefault),
                  style: AppTypography.headlineSm.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: FilledButton.icon(
                onPressed: enabled ? _add : null,
                icon: _adding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.shopping_bag_outlined, size: 18),
                label: Text(_adding ? l10n.loading : l10n.addFor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.single,
    required this.onTap,
  });

  final MenuOption option;
  final bool selected;
  final bool single;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final enabled = option.available;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(
              single
                  ? (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked)
                  : (selected ? Icons.check_box : Icons.check_box_outline_blank),
              size: 20,
              color: enabled
                  ? (selected ? AppColors.primary : AppColors.secondary)
                  : AppColors.surfaceDim,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                option.name(l10n.isArabic),
                style: AppTypography.bodyMd.copyWith(
                  color: enabled ? AppColors.onSurface : AppColors.surfaceDim,
                ),
              ),
            ),
            if (option.priceDeltaMinor != 0)
              Text(
                '${option.priceDeltaMinor > 0 ? '+' : ''}${Fmt.money(option.priceDeltaMinor)}',
                style: AppTypography.labelMd.copyWith(
                  color: enabled ? AppColors.primary : AppColors.surfaceDim,
                ),
              ),
            if (!enabled) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.unavailable,
                style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
        ],
      ),
    );
  }
}
