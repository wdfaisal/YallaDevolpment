import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/debouncer.dart';
import '../data/api/api_exception.dart';
import '../data/models/search.dart';
import 'address_controller.dart';
import 'providers.dart';
import 'session_controller.dart';

class SearchState {
  const SearchState({
    this.config,
    this.query = '',
    this.suggestions = const [],
    this.results,
    this.history = const [],
    this.suggesting = false,
    this.searching = false,
    this.hasSearched = false,
    this.error,
  });

  final SearchConfig? config;
  final String query;
  final List<SearchSuggestion> suggestions;
  final SearchResults? results;
  final List<SearchHistoryItem> history;
  final bool suggesting;
  final bool searching;
  final bool hasSearched;
  final String? error;

  int get minQueryLength => config?.minQueryLength ?? 2;
  int get debounceMs => config?.debounceMs ?? 300;
  bool get canSearch => query.trim().length >= minQueryLength;

  SearchState copyWith({
    SearchConfig? config,
    String? query,
    List<SearchSuggestion>? suggestions,
    SearchResults? results,
    List<SearchHistoryItem>? history,
    bool? suggesting,
    bool? searching,
    bool? hasSearched,
    String? error,
    bool clearResults = false,
    bool clearSuggestions = false,
    bool clearError = false,
  }) {
    return SearchState(
      config: config ?? this.config,
      query: query ?? this.query,
      suggestions: clearSuggestions ? const [] : (suggestions ?? this.suggestions),
      results: clearResults ? null : (results ?? this.results),
      history: history ?? this.history,
      suggesting: suggesting ?? this.suggesting,
      searching: searching ?? this.searching,
      hasSearched: hasSearched ?? this.hasSearched,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final searchProvider = NotifierProvider<SearchController, SearchState>(SearchController.new);

class SearchController extends Notifier<SearchState> {
  Debouncer? _debouncer;
  CancelToken? _suggestToken;
  CancelToken? _resultsToken;
  bool _initialised = false;

  @override
  SearchState build() {
    ref.onDispose(() {
      _debouncer?.dispose();
      _suggestToken?.cancel();
      _resultsToken?.cancel();
    });
    return const SearchState();
  }

  /// Loads admin search settings and (for signed-in customers) history once.
  Future<void> ensureInitialised() async {
    if (_initialised) return;
    _initialised = true;
    _debouncer = Debouncer(duration: Duration(milliseconds: state.debounceMs));
    try {
      final config = await ref.read(searchRepositoryProvider).config();
      _debouncer = Debouncer(duration: Duration(milliseconds: config.debounceMs));
      state = state.copyWith(config: config);
    } catch (_) {
      // Defaults keep search usable when settings cannot be loaded.
    }
    await loadHistory();
  }

  Future<void> loadHistory() async {
    if (ref.read(sessionProvider).valueOrNull == null) return;
    try {
      final history = await ref.read(searchRepositoryProvider).history();
      state = state.copyWith(history: history);
    } on ApiException {
      // History is optional; failures must not block searching.
    }
  }

  void onQueryChanged(String text) {
    final trimmed = text.trim();
    state = state.copyWith(
      query: text,
      clearResults: true,
      hasSearched: false,
      clearError: true,
    );
    _suggestToken?.cancel();
    if (trimmed.length < state.minQueryLength) {
      _debouncer?.cancel();
      state = state.copyWith(clearSuggestions: true, suggesting: false);
      return;
    }
    _debouncer?.run(() => _suggest(trimmed));
  }

  Future<void> _suggest(String query) async {
    final token = CancelToken();
    _suggestToken = token;
    state = state.copyWith(suggesting: true, clearError: true);
    try {
      final address = ref.read(selectedAddressProvider);
      final response = await ref.read(searchRepositoryProvider).suggest(
            query,
            addressId: address?.id,
            lat: address?.lat,
            lng: address?.lng,
            limit: state.config?.suggestionLimit,
            cancelToken: token,
          );
      if (_suggestToken != token) return;
      state = state.copyWith(suggestions: response.suggestions, suggesting: false);
    } on ApiException catch (error) {
      if (error.code == 'CANCELLED') return;
      if (_suggestToken != token) return;
      state = state.copyWith(suggesting: false, clearSuggestions: true);
    }
  }

  /// Runs a full search only when the customer explicitly submits.
  Future<void> submit([String? text]) async {
    final query = (text ?? state.query).trim();
    if (query.length < state.minQueryLength) return;
    _debouncer?.cancel();
    _suggestToken?.cancel();
    _resultsToken?.cancel();
    final token = CancelToken();
    _resultsToken = token;

    state = state.copyWith(
      query: query,
      searching: true,
      hasSearched: true,
      clearSuggestions: true,
      clearError: true,
    );
    try {
      final address = ref.read(selectedAddressProvider);
      final results = await ref.read(searchRepositoryProvider).results(
            query,
            addressId: address?.id,
            lat: address?.lat,
            lng: address?.lng,
            pageSize: state.config?.pageSize,
            cancelToken: token,
          );
      if (_resultsToken != token) return;
      state = state.copyWith(results: results, searching: false);
      await loadHistory();
    } on ApiException catch (error) {
      if (error.code == 'CANCELLED') return;
      if (_resultsToken != token) return;
      state = state.copyWith(searching: false, error: error.message);
    }
  }

  void clearQuery() {
    _debouncer?.cancel();
    _suggestToken?.cancel();
    _resultsToken?.cancel();
    state = state.copyWith(
      query: '',
      clearSuggestions: true,
      clearResults: true,
      hasSearched: false,
      suggesting: false,
      searching: false,
      clearError: true,
    );
  }
  Future<void> clearHistory() async {
    await ref.read(searchRepositoryProvider).clearHistory();
    state = state.copyWith(history: const []);
  }

  Future<void> deleteHistoryItem(String id) async {
    await ref.read(searchRepositoryProvider).deleteHistoryItem(id);
    state = state.copyWith(
      history: state.history.where((item) => item.id != id).toList(growable: false),
    );
  }

  Future<void> recordClick({required String targetType, required String targetId}) async {
    if (ref.read(sessionProvider).valueOrNull == null) return;
    try {
      await ref.read(searchRepositoryProvider).recordClick(
            targetType: targetType,
            targetId: targetId,
          );
    } on ApiException {
      // Personalisation signals are best-effort.
    }
  }
}
