import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/data/api/api_client.dart';
import 'package:yalla_talabat_customer/data/api/token_store.dart';
import 'package:yalla_talabat_customer/data/push/push_service.dart';
import 'package:yalla_talabat_customer/data/repositories/account_repository.dart';

/// The build used by tests has no Firebase credentials. Every push entry point
/// must then behave as an honest no-op so the in-app notification center keeps
/// working without inventing delivery.
void main() {
  PushService buildService() {
    final tokenStore = TokenStore();
    return PushService(
      accountRepository: AccountRepository(ApiClient(tokenStore: tokenStore)),
      tokenStore: tokenStore,
    );
  }

  test('reports unconfigured and never touches Firebase', () async {
    final service = buildService();

    expect(service.isConfigured, isFalse);
    expect(await service.initialize(), PushStatus.unconfigured);
    expect(service.status, PushStatus.unconfigured);
  });

  test('exposes empty message streams when unconfigured', () async {
    final service = buildService();
    await service.initialize();

    expect(await service.foregroundMessages.toList(), isEmpty);
    expect(await service.openedMessages.toList(), isEmpty);
    expect(await service.tokenRefreshes.toList(), isEmpty);
  });

  test('cannot register a token without Firebase', () async {
    final service = buildService();
    await service.initialize();

    expect(await service.requestPermission(), isFalse);
    expect(await service.currentToken(), isNull);
    expect(await service.registerCurrentToken(), isFalse);
    expect(await service.initialMessage(), isNull);
  });

  test('unregistering a stored token is a safe no-op', () async {
    final service = buildService();
    await service.initialize();

    await expectLater(service.unregisterStoredToken(), completes);
  });
}
