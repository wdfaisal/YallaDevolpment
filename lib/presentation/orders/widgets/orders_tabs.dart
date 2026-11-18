import 'package:flutter/material.dart';

import '../../shared/segmented_tabs.dart';

/// Flat segmented control for the My Orders page, built on [SegmentedTabs].
class OrdersTabs extends StatelessWidget {
  const OrdersTabs({
    super.key,
    required this.activeLabel,
    required this.pastLabel,
    required this.active,
    required this.onSelect,
  });

  final String activeLabel;
  final String pastLabel;
  final bool active;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return SegmentedTabs(
      items: [
        SegmentedTabItem(label: activeLabel),
        SegmentedTabItem(label: pastLabel),
      ],
      selectedIndex: active ? 0 : 1,
      onSelect: (index) => onSelect(index == 0),
    );
  }
}
