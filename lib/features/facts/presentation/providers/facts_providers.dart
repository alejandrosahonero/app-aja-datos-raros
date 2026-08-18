import 'package:aja/features/facts/data/fact_repository.dart';
import 'package:aja/features/facts/data/fact_share_service.dart';
import 'package:aja/features/facts/domain/fact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the parsed catalogue for the process lifetime, so switching category
/// or restarting the deck never re-reads the asset.
final Provider<FactRepository> factRepositoryProvider =
    Provider<FactRepository>((Ref ref) => FactRepository());

/// The whole catalogue, unfiltered. Read-only, so `autoDispose` is correct: the
/// repository cache is what makes a re-subscription free.
final FutureProvider<List<Fact>> factsProvider = FutureProvider<List<Fact>>(
  (Ref ref) => ref.watch(factRepositoryProvider).loadAll(),
  isAutoDispose: true,
);

/// Stateless plumbing around the OS share sheet, so a plain [Provider].
final Provider<FactShareService> factShareServiceProvider =
    Provider<FactShareService>((Ref ref) => const FactShareService());

/// Selected category, or `null` for "all". Kept out of the deck state so that
/// picking a category simply rebuilds the deck instead of mutating it in place.
final NotifierProvider<FactCategoryFilter, FactCategory?>
categoryFilterProvider = NotifierProvider<FactCategoryFilter, FactCategory?>(
  FactCategoryFilter.new,
);

class FactCategoryFilter extends Notifier<FactCategory?> {
  @override
  FactCategory? build() => null;

  void select(FactCategory? category) => state = category;
}
