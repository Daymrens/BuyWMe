import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/autocomplete_service.dart';

final autocompleteServiceProvider = Provider((ref) {
  return AutocompleteService();
});

final suggestionsProvider = StateNotifierProvider<SuggestionsNotifier, List<String>>((ref) {
  final service = ref.watch(autocompleteServiceProvider);
  return SuggestionsNotifier(service);
});

class SuggestionsNotifier extends StateNotifier<List<String>> {
  final AutocompleteService _service;

  SuggestionsNotifier(this._service) : super([]) {
    _service.indexItems();
  }

  void updateSuggestions(String query) {
    if (query.isEmpty) {
      state = [];
    } else {
      state = _service.getSuggestions(query);
    }
  }

  void clearSuggestions() {
    state = [];
  }

  int getFrequency(String itemName) {
    return _service.getItemFrequency(itemName);
  }

  bool isFavorite(String itemName) {
    return _service.isFavorite(itemName);
  }

  void refreshIndex() {
    _service.indexItems();
    clearSuggestions();
  }
}

