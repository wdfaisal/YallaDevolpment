import 'package:flutter/material.dart';

import '../../data/models/catalog.dart';
import '../restaurant/meal_drawer.dart';

/// Opens a meal by id. Used by banners, offers, favorites and search results
/// where the full menu item is not loaded yet.
Future<void> openMeal(
  BuildContext context,
  String menuItemId, {
  bool restaurantOpen = true,
}) {
  return showMealDrawer(
    context,
    menuItemId: menuItemId,
    restaurantOpen: restaurantOpen,
  );
}

/// Opens an already loaded menu item without an extra request.
Future<void> openLoadedMeal(
  BuildContext context,
  CatalogMenuItem item, {
  bool restaurantOpen = true,
}) {
  return showMealDrawer(
    context,
    item: item,
    restaurantOpen: restaurantOpen,
  );
}
