import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/catalog.dart';
import '../../state/address_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import 'widgets/meal_drawer_widgets.dart';

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
    barrierColor: Colors.black.withValues(alpha: 0.32),
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
    var total = item.effectivePriceMinor;
    for (final group in item.optionGroups) {
      final chosen = _selected[group.id] ?? const <String>{};
      for (final option in group.options) {
        if (chosen.contains(option.id)) total += option.priceDeltaMinor;
      }
    }
    return total;
  }

  List<String> get _optionIds =>
      _selected.values.expand((e) => e).toList(growable: false);

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
    final item = _item;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: media.size.height * 0.92,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(child: _content(l10n)),
            if (item != null)
              MealActionBar(
                quantity: _quantity,
                totalMinor: _unitMinor * _quantity,
                currency: l10n.currencyDefault,
                l10n: l10n,
                onQuantity: (value) => setState(() => _quantity = value),
                onAdd: _add,
                adding: _adding,
                enabled: item.available && !_adding,
              ),
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
        MealHero(
          item: item,
          l10n: l10n,
          onClose: () => Navigator.of(context).pop(),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!item.available) ...[
                const _UnavailableBanner(),
                const SizedBox(height: AppSpacing.md),
              ],
              MealHeading(item: item, l10n: l10n),
            ],
          ),
        ),
        for (final group in item.optionGroups)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              0,
            ),
            child: MealOptionSection(
              group: group,
              selected: _selected[group.id] ?? const <String>{},
              l10n: l10n,
              onToggle: (option) => _toggle(group, option),
            ),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            0,
          ),
          child: MealNotesField(controller: _notes, l10n: l10n),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _UnavailableBanner extends StatelessWidget {
  const _UnavailableBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: AppColors.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.itemUnavailable,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
