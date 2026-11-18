import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/maps.dart';
import '../../../data/models/orders.dart';

/// Full-bleed live map from the Stitch tracking design.
///
/// It replaces the flat route strip with a real map: the restaurant pickup pin,
/// the captain's latest live position and the customer destination are fitted
/// into the camera, with a travelled route and a dashed remaining route. Every
/// overlay is flat white with a hairline border; nothing casts a shadow.
class TrackingMapHero extends StatefulWidget {
  const TrackingMapHero({
    super.key,
    required this.detail,
    required this.l10n,
    required this.height,
    required this.onBack,
    this.onCancel,
    this.tiles,
    this.route,
    this.loadTiles = true,
    this.animatePulse = true,
  });

  final OrderDetail detail;
  final L10n l10n;
  final double height;
  final VoidCallback onBack;

  /// Shows a cancel action in the title row while the order can still be
  /// cancelled; `null` keeps the row to the back button and the title.
  final VoidCallback? onCancel;

  /// Server-owned tile wiring. `null` while the backend config loads, or when
  /// the backend has no raster source; the map then draws without tiles and the
  /// page keeps its honest "map unavailable" state instead of a fake map.
  final MapTiles? tiles;

  /// Real road route from the routing provider. When present the map draws the
  /// provider geometry; when absent it falls back to a clearly dashed direct
  /// line and the page shows no road distance.
  final MapRoute? route;

  /// Disabled in widget tests so no network tile request is attempted.
  final bool loadTiles;

  /// Disabled in widget tests so no infinite animation keeps the tree busy.
  final bool animatePulse;

  @override
  State<TrackingMapHero> createState() => _TrackingMapHeroState();
}

class _TrackingMapHeroState extends State<TrackingMapHero>
    with SingleTickerProviderStateMixin {
  final MapController _map = MapController();
  late final AnimationController _pulse;

  /// One long-lived provider per tile template so the underlying HTTP client is
  /// reused across rebuilds and disposed with the page.
  NetworkTileProvider? _tileProvider;

  /// Template plus authorisation of the provider currently alive. A new session
  /// token must rebuild the provider even when the URL is unchanged.
  String? _tileSignature;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _syncPulse();
    _syncTileProvider();
  }

  @override
  void didUpdateWidget(covariant TrackingMapHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
    _syncTileProvider();
  }

  void _syncTileProvider() {
    final tiles = widget.loadTiles ? widget.tiles : null;
    final signature = tiles == null
        ? null
        : '${tiles.urlTemplate}|${tiles.headers.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    if (signature == _tileSignature) return;
    _tileProvider?.dispose();
    _tileSignature = signature;
    _tileProvider =
        tiles == null ? null : NetworkTileProvider(headers: tiles.headers);
  }

  void _syncPulse() {
    final shouldPulse =
        widget.animatePulse && widget.detail.tracking.driver?.position != null;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _tileProvider?.dispose();
    _map.dispose();
    super.dispose();
  }

  LatLng? get _restaurant {
    final point = widget.detail.restaurantPosition;
    return point == null ? null : LatLng(point.lat, point.lng);
  }

  LatLng? get _destination {
    final point = widget.detail.deliveryPosition;
    return point == null ? null : LatLng(point.lat, point.lng);
  }

  LatLng? get _driver {
    final point = widget.detail.tracking.driver?.position;
    return point == null ? null : LatLng(point.lat, point.lng);
  }

  List<LatLng> get _points {
    final points = <LatLng>{};
    final restaurant = _restaurant;
    final driver = _driver;
    final destination = _destination;
    if (restaurant != null) points.add(restaurant);
    if (driver != null) points.add(driver);
    if (destination != null) points.add(destination);
    return points.toList();
  }

  /// Provider geometry of the road route; empty when routing is unavailable.
  List<LatLng> get _routePoints {
    final route = widget.route;
    if (route == null) return const [];
    return [
      for (final point in route.points) LatLng(point.lat, point.lng),
    ];
  }

  /// What the camera must contain: the whole road route plus the captain, or
  /// the markers while no route is available.
  List<LatLng> get _fitPoints {
    final routePoints = _routePoints;
    if (routePoints.length < 2) return _points;
    final points = <LatLng>{...routePoints};
    final driver = _driver;
    if (driver != null) points.add(driver);
    return points.toList();
  }

  void _fit({bool animated = false}) {
    final points = _fitPoints;
    if (points.isEmpty) return;
    if (points.length == 1) {
      _map.move(points.first, 15);
      return;
    }
    final camera = CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: const EdgeInsets.fromLTRB(72, 96, 72, 96),
    );
    if (animated) {
      _map.fitCamera(camera);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final topInset = MediaQuery.paddingOf(context).top;
    final points = _points;
    final fitPoints = _fitPoints;
    final routePoints = _routePoints;
    final center =
        fitPoints.isEmpty ? const LatLng(15.55, 32.55) : fitPoints.first;
    final driver = _driver;
    final restaurant = _restaurant;
    final destination = _destination;
    final tiles = widget.loadTiles ? widget.tiles : null;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          if (points.isEmpty)
            _MapFallback(l10n: l10n)
          else
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
                initialCameraFit: fitPoints.length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(fitPoints),
                        padding: const EdgeInsets.fromLTRB(72, 96, 72, 96),
                      )
                    : null,
                minZoom: 9,
                maxZoom: 18,
                backgroundColor: AppColors.surfaceContainerLowest,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                if (tiles != null && _tileProvider != null)
                  TileLayer(
                    urlTemplate: tiles.urlTemplate,
                    tileProvider: _tileProvider,
                    userAgentPackageName: 'com.yallatalabat.customer',
                    minZoom: tiles.minZoom,
                    maxZoom: tiles.maxZoom,
                    maxNativeZoom: tiles.maxZoom.round(),
                  ),
                if (routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      // The provider's road geometry, not a straight line.
                      Polyline(
                        points: routePoints,
                        strokeWidth: 6,
                        color: AppColors.primary,
                        borderColor: AppColors.surfaceContainerLowest,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  )
                else if (restaurant != null && destination != null)
                  PolylineLayer(
                    polylines: [
                      // Routing is unavailable: show an explicitly dashed
                      // direct line and never claim it is a road route.
                      Polyline(
                        points: [restaurant, destination],
                        color: AppColors.surfaceContainerHigh,
                        strokeWidth: 4,
                        pattern: StrokePattern.dashed(
                          segments: const [8, 6],
                        ),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (restaurant != null)
                      Marker(
                        point: restaurant,
                        width: 190,
                        height: 72,
                        alignment: const Alignment(0, -0.5),
                        child: _RestaurantMarker(
                          label: widget.detail.summary.restaurantName ?? '',
                        ),
                      ),
                    if (destination != null)
                      Marker(
                        point: destination,
                        width: 190,
                        height: 72,
                        alignment: const Alignment(0, -0.5),
                        child: _DestinationMarker(
                          label: _shortAddress(widget.detail.deliveryAddress),
                        ),
                      ),
                    if (driver != null)
                      Marker(
                        point: driver,
                        width: 190,
                        height: 84,
                        alignment: const Alignment(0, 0.5),
                        child: _DriverMarker(
                          name: widget.detail.tracking.driver?.name ?? '',
                          movingLabel: l10n.movingNow,
                          pulse: widget.animatePulse ? _pulse : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfaceContainerLowest.withValues(alpha: 0.72),
                    AppColors.surfaceContainerLowest.withValues(alpha: 0),
                  ],
                ),
              ),
              child: SizedBox(height: topInset + 92, width: double.infinity),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 56,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surfaceContainerLowest.withValues(alpha: 0),
                      AppColors.surfaceContainerLowest,
                    ],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: topInset + AppSpacing.md,
            start: AppSpacing.lg,
            end: AppSpacing.lg,
            child: Row(
              children: [
                _MapCircleButton(
                  // `arrow_back` mirrors to a right-pointing arrow in RTL.
                  icon: Icons.arrow_back,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onTap: widget.onBack,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _TitlePill(label: l10n.trackOrderTitle),
                  ),
                ),
                if (widget.onCancel != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _HeaderCancelAction(
                    label: l10n.cancelOrder,
                    onTap: widget.onCancel!,
                  ),
                ],
              ],
            ),
          ),
          PositionedDirectional(
            top: topInset + 64,
            start: AppSpacing.lg,
            end: AppSpacing.lg,
            child: Center(
              child: _LiveStatusPill(detail: widget.detail, l10n: l10n),
            ),
          ),
          if (points.isNotEmpty)
            Positioned(
              left: AppSpacing.lg,
              bottom: AppSpacing.lg + 8,
              child: _MapCircleButton(
                icon: Icons.my_location,
                tooltip: l10n.recenterMap,
                onTap: () => _fit(animated: true),
              ),
            ),
          Positioned(
            right: AppSpacing.sm,
            bottom: 2,
            child: IgnorePointer(
              child: Text(
                // The provider attribution is server-owned; the localized
                // fallback only covers the moment before the config arrives.
                tiles?.attribution ?? l10n.mapAttribution,
                style: AppTypography.labelSm.copyWith(
                  fontSize: 8,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortAddress(String address) {
    final first = address.split(RegExp(r'[,،]')).first.trim();
    return first.isEmpty ? address : first;
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.l10n});

  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceContainerLowest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 40,
                color: AppColors.secondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.mapUnavailable,
                textAlign: TextAlign.center,
                style:
                    AppTypography.bodySm.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantMarker extends StatelessWidget {
  const _RestaurantMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _MapLabel(
          icon: Icons.restaurant,
          text: label,
          background: AppColors.surfaceContainerLowest,
          foreground: AppColors.onSurface,
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.storefront,
            size: 18,
            color: AppColors.onPrimary,
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.tertiary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home, size: 14, color: AppColors.onTertiary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderHairline),
          ),
          child: const Icon(
            Icons.location_on,
            size: 17,
            color: AppColors.tertiary,
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }
}

class _DriverMarker extends StatelessWidget {
  const _DriverMarker({
    required this.name,
    required this.movingLabel,
    required this.pulse,
  });

  final String name;
  final String movingLabel;
  final Animation<double>? pulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (pulse != null)
                AnimatedBuilder(
                  animation: pulse!,
                  builder: (context, child) {
                    final t = pulse!.value;
                    return Opacity(
                      opacity: (1 - t) * 0.35,
                      child: Transform.scale(
                        scale: 0.9 + t * 0.8,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surfaceContainerLowest,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  size: 21,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: AppColors.onSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            '$name ($movingLabel)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.surfaceContainerLowest,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 168),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSm.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page title pill floating over the map, matching the flat white overlays.
class _TitlePill extends StatelessWidget {
  const _TitlePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.headlineSm,
      ),
    );
  }
}

/// Outlined rectangular cancel action pinned to the left edge of the title
/// row: transparent fill, hairline red border and the small red label.
class _HeaderCancelAction extends StatelessWidget {
  const _HeaderCancelAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTapTarget,
            minWidth: AppSpacing.minTapTarget,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close, size: 14, color: AppColors.error),
                  const SizedBox(width: 2),
                  Text(
                    label,
                    maxLines: 1,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveStatusPill extends StatelessWidget {
  const _LiveStatusPill({required this.detail, required this.l10n});

  final OrderDetail detail;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;
    final eta = detail.tracking.etaMinutes;
    final live = summary.isActive;
    final label = live && eta != null
        ? '${l10n.arrivingIn} $eta ${l10n.minuteShort}'
        : summary.statusLabel(l10n.isArabic);
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: live ? AppColors.tertiary : AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w700,
                color: live ? AppColors.onSurface : AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  const _MapCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceContainerLowest,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.borderHairline),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: AppSpacing.minTapTarget,
            height: AppSpacing.minTapTarget,
            child: Icon(icon, size: 20, color: AppColors.onSurface),
          ),
        ),
      ),
    );
  }
}
