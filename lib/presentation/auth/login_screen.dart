import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/customer.dart';
import '../../state/language_controller.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';

/// Phone + OTP sign in (BRD §6.2). The code is generated and verified by the
/// backend; SMS/WhatsApp delivery is blocked pending L-05, so non-production
/// builds surface the development code returned by the API.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.next});

  /// Route to open after a successful sign-in (cart, favorites, …).
  final String? next;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();

  OtpChallenge? _challenge;
  Timer? _timer;
  int _resendLeft = 0;
  int _expiresLeft = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _onOtpStep => _challenge != null;

  String _normalize(String input) => input.trim().replaceAll(RegExp(r'[\s\-().]'), '');

  bool _validPhone(String input) => RegExp(r'^\+?\d{7,15}$').hasMatch(_normalize(input));

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendLeft > 0) _resendLeft--;
        if (_expiresLeft > 0) _expiresLeft--;
        if (_resendLeft == 0 && _expiresLeft == 0) timer.cancel();
      });
    });
  }

  String _clock(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  Future<void> _requestCode({bool resend = false}) async {
    final l10n = L10n.of(context);
    if (!_validPhone(_phone.text)) {
      setState(() => _error = l10n.invalidPhone);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await ref.read(authRepositoryProvider).requestOtp(
            phone: _normalize(_phone.text),
            language: ref.read(languageProvider),
          );
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _busy = false;
        _resendLeft = challenge.resendInSeconds;
        _expiresLeft = challenge.expiresInSeconds;
      });
      _startTimer();
      if (resend) {
        showAppSnack(context, l10n.otpResent);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.somethingWentWrong;
      });
    }
  }

  Future<void> _verify() async {
    final l10n = L10n.of(context);
    final code = _code.text.trim();
    if (!RegExp(r'^\d{4,8}$').hasMatch(code)) {
      setState(() => _error = l10n.invalidCode);
      return;
    }
    if (_expiresLeft <= 0) {
      setState(() => _error = l10n.codeExpired);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final name = _name.text.trim();
      final session = await ref.read(authRepositoryProvider).verifyOtp(
            phone: _normalize(_phone.text),
            code: code,
            name: name.length >= 2 ? name : null,
            language: ref.read(languageProvider),
          );
      await ref.read(sessionProvider.notifier).signIn(session);
      if (!mounted) return;
      setState(() => _busy = false);
      _finish();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.somethingWentWrong;
      });
    }
  }

  void _finish() {
    final next = widget.next;
    if (next != null && next.startsWith('/') && !next.startsWith('/login')) {
      context.pushReplacement(next);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _changePhone() {
    _timer?.cancel();
    setState(() {
      _challenge = null;
      _code.clear();
      _name.clear();
      _resendLeft = 0;
      _expiresLeft = 0;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return AppScaffold(
      header: SimpleHeader(title: l10n.loginTitle, onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xxl,
          AppSpacing.xxl,
          AppSpacing.xxxl,
        ),
        children: [
          _brand(l10n),
          const SizedBox(height: AppSpacing.xxl),
          if (!_onOtpStep) ..._phoneStep(l10n) else ..._otpStep(l10n),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            _errorBox(_error!),
          ],
        ],
      ),
    );
  }

  Widget _brand(L10n l10n) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            color: AppColors.orangeTintSubtle,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delivery_dining, size: 42, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.appName, style: AppTypography.headlineLgMobile),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.loginSubtitle,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }

  List<Widget> _phoneStep(L10n l10n) {
    return [
      Text(l10n.phone, style: AppTypography.labelLg),
      const SizedBox(height: AppSpacing.sm),
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.telephoneNumber],
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-().]')),
        ],
        onSubmitted: (_) => _requestCode(),
        style: AppTypography.bodyLg,
        decoration: InputDecoration(
          hintText: l10n.phoneHint,
          prefixIcon: const Icon(Icons.phone_iphone, color: AppColors.secondary),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: _busy ? null : _requestCode,
          child: _busy
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.sendingCode),
                  ],
                )
              : Text(l10n.sendCode),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        l10n.privacyNotice,
        textAlign: TextAlign.center,
        style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
      ),
    ];
  }

  List<Widget> _otpStep(L10n l10n) {
    final challenge = _challenge!;
    final masked = challenge.phone;
    return [
      Text(l10n.otpTitle, style: AppTypography.headlineSm),
      const SizedBox(height: AppSpacing.xs),
      Text(
        '${l10n.otpSubtitle} $masked',
        style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
      ),
      const SizedBox(height: AppSpacing.xl),
      TextField(
        controller: _code,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
        style: AppTypography.headlineMd.copyWith(letterSpacing: 8),
        decoration: InputDecoration(hintText: l10n.enterCodeHint),
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '${l10n.otpExpiresIn} ${_clock(_expiresLeft)}',
              style: AppTypography.labelSm.copyWith(
                color: _expiresLeft <= 30 ? AppColors.error : AppColors.secondary,
              ),
            ),
          ),
          TextButton(
            onPressed: _busy || _resendLeft > 0 ? null : () => _requestCode(resend: true),
            child: Text(
              _resendLeft > 0 ? '${l10n.resendIn} ${_clock(_resendLeft)}' : l10n.resend,
            ),
          ),
        ],
      ),
      if (challenge.debugCode != null && challenge.debugCode!.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.code, size: 18, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${l10n.devCode}: ${challenge.debugCode}',
                  style: AppTypography.labelMd,
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.nameHint, style: AppTypography.labelLg),
      const SizedBox(height: AppSpacing.sm),
      TextField(
        controller: _name,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _verify(),
        style: AppTypography.bodyLg,
        decoration: InputDecoration(
          hintText: l10n.fullName,
          prefixIcon: const Icon(Icons.person_outline, color: AppColors.secondary),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: _busy ? null : _verify,
          child: _busy
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.verifying),
                  ],
                )
              : Text(l10n.verify),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Center(
        child: TextButton.icon(
          onPressed: _busy ? null : _changePhone,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(l10n.changePhone),
        ),
      ),
    ];
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySm.copyWith(color: AppColors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
