library;

import 'package:aja/features/facts/data/fact_repository.dart';
import 'package:aja/features/facts/domain/fact.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the shipped catalogue itself, not just the parser.
///
/// `assets/data/facts.json` is hand written and grows with every content batch.
/// A typo in a category id or a missing field would only show up as a blank
/// screen on a real device, so it has to fail here instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Fact> facts;

  setUpAll(() async {
    facts = await FactRepository().loadAll();
  });

  test('the bundled catalogue parses and is not empty', () {
    expect(facts, isNotEmpty);
  });

  test('every fact id is unique', () {
    final Set<String> ids = facts.map((Fact fact) => fact.id).toSet();
    expect(ids, hasLength(facts.length));
  });

  test('no fact ships without a source', () {
    // Editorial rule: an unsourced "fun fact" is what turns into 1-star
    // reviews when it gets debunked.
    for (final Fact fact in facts) {
      expect(
        fact.source.trim(),
        isNotEmpty,
        reason: 'Missing source: ${fact.id}',
      );
    }
  });

  test('no fact ships with empty text in either language', () {
    for (final Fact fact in facts) {
      for (final LocalizedText text in <LocalizedText>[
        fact.question,
        fact.answer,
        fact.detail,
      ]) {
        expect(text.es.trim(), isNotEmpty, reason: 'Empty es in ${fact.id}');
        expect(text.en.trim(), isNotEmpty, reason: 'Empty en in ${fact.id}');
      }
    }
  });

  test('every category has at least one fact', () {
    for (final FactCategory category in FactCategory.values) {
      expect(
        facts.where((Fact fact) => fact.category == category),
        isNotEmpty,
        reason: 'Category ${category.id} would render an empty deck',
      );
    }
  });
}
