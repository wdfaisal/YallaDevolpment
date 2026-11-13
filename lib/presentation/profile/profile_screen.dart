import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/customer.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';

/// Edit the signed-in customer's name and email. The phone number is the
/// identity used by the OTP flow, so it is read-only here.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final session = ref.watch(sessionProvider);

    return AppScaffold(
      header: SimpleHeader(
        title: l10n.editProfile,
        onBack: () => context.pop(),
      ),
      body: AsyncView(
        value: session,
        onRetry: () => ref.read(sessionProvider.notifier).refresh(),
        builder: (profile) {
          if (profile == null) {
            return EmptyState(
              title: l10n.editProfile,
              message: l10n.notAuthorized,
              icon: Icons.person_outline,
              actionLabel: l10n.signIn,
              onAction: () => context.push('/login?next=/account/profile'),
            );
          }
          return _ProfileForm(key: ValueKey(profile.id), profile: profile);
        },
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({super.key, required this.profile});

  final CustomerProfile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController _name =
      TextEditingController(text: widget.profile.name);
  late final TextEditingController _email =
      TextEditingController(text: widget.profile.email ?? '');

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = L10n.of(context);
    final name = _name.text.trim();
    final email = _email.text.trim();

    if (name.length < 2) {
      setState(() => _error = l10n.nameRequired);
      return;
    }
    if (email.isNotEmpty && !_isEmail(email)) {
      setState(() => _error = l10n.invalidValue);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(sessionProvider.notifier).updateProfile(
            name: name,
            email: email.isEmpty ? null : email,
            clearEmail: email.isEmpty && widget.profile.email != null,
          );
      if (!mounted) return;
      setState(() => _busy = false);
      showAppSnack(context, l10n.profileUpdated);
      if (context.canPop()) context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            error is ApiException ? error.message : l10n.somethingWentWrong;
      });
    }
  }

  bool _isEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final profile = widget.profile;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.orangeTintSubtle,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: AppColors.borderMuted),
                ),
                clipBehavior: Clip.antiAlias,
                child: profile.avatarUrl != null
                    ? AppImage(
                        url: profile.avatarUrl,
                        borderRadius: BorderRadius.zero,
                      )
                    : Center(
                        child: Text(
                          profile.initials.isEmpty ? '?' : profile.initials,
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${l10n.memberSince} ${Fmt.date(profile.memberSince)}',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: profile.isSuspended
                      ? AppColors.errorContainer
                      : AppColors.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  profile.isSuspended ? l10n.statusSuspended : l10n.statusActive,
                  style: AppTypography.labelSm.copyWith(
                    color: profile.isSuspended
                        ? AppColors.onErrorContainer
                        : AppColors.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _label(l10n.fullName),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _name,
          maxLength: 190,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          style: AppTypography.bodyLg,
          decoration: InputDecoration(
            hintText: l10n.fullName,
            counterText: '',
            prefixIcon:
                const Icon(Icons.person_outline, color: AppColors.secondary),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _label(l10n.phone),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  profile.phone,
                  style: AppTypography.bodyLg,
                  textDirection: TextDirection.ltr,
                ),
              ),
              const Icon(
                Icons.lock_outline,
                size: 18,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.phoneReadOnly,
          style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        _label(l10n.email),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          style: AppTypography.bodyLg,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            hintText: l10n.emailHint,
            prefixIcon:
                const Icon(Icons.mail_outline, color: AppColors.secondary),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: AppColors.onErrorContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _error!,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.saveChanges),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(text, style: AppTypography.labelLg);
  }
}
