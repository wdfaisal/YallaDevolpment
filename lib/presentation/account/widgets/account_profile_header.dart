import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_image.dart';

/// Avatar, name and contact details block from the Stitch profile design.
class AccountProfileHeader extends StatelessWidget {
  const AccountProfileHeader({
    super.key,
    required this.name,
    required this.phone,
    required this.initials,
    required this.avatarUrl,
    required this.onEdit,
    this.email,
    this.changePhotoTooltip = '',
  });

  final String name;
  final String phone;
  final String initials;
  final String? avatarUrl;
  final String? email;
  final VoidCallback onEdit;
  final String changePhotoTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _Avatar(
            initials: initials,
            avatarUrl: avatarUrl,
            onEdit: onEdit,
            tooltip: changePhotoTooltip,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTypography.headlineSm.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.profileHeading,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.profileSecondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 11,
                      color: AppColors.profileMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.avatarUrl,
    required this.onEdit,
    required this.tooltip,
  });

  final String initials;
  final String? avatarUrl;
  final VoidCallback onEdit;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.profileSurfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.profileChip, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.profileCardShadow,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? AppImage(url: avatarUrl, borderRadius: BorderRadius.zero)
                : Center(
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.profileAccent,
                      ),
                    ),
                  ),
          ),
          Positioned(
            bottom: -2,
            left: -2,
            child: Tooltip(
              message: tooltip,
              child: Material(
                color: AppColors.profileAccent,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEdit,
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
