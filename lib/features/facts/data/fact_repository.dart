import 'dart:convert';

import 'package:aja/core/errors/app_exception.dart';
import 'package:aja/features/facts/domain/fact.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Parses the catalogue. Top level on purpose: [compute] can only run a
/// function that is not a closure.
@visibleForTesting
List<Fact> parseFacts(String raw) {
  final Map<String, dynamic> root = jsonDecode(raw) as Map<String, dynamic>;
  final List<dynamic> entries = root['facts']! as List<dynamic>;

  return List<Fact>.unmodifiable(
    entries.map(
      (dynamic entry) => Fact.fromJson(entry as Map<String, dynamic>),
    ),
  );
}

/// Reads the bundled question catalogue.
///
/// No backend in the MVP: the JSON travels inside the APK. Parsing runs on a
/// background isolate through [compute] because the catalogue is meant to grow
/// to hundreds of entries and this load happens while the first screen is being
/// painted.
///
/// The result is cached for the process lifetime — the asset cannot change
/// underneath us, so re-reading it would only cost frames.
class FactRepository {
  FactRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String assetPath = 'assets/data/facts.json';

  final AssetBundle _bundle;
  List<Fact>? _cache;

  Future<List<Fact>> loadAll() async {
    final List<Fact>? cached = _cache;
    if (cached != null) return cached;

    try {
      final String raw = await _bundle.loadString(assetPath);
      final List<Fact> facts = await compute(parseFacts, raw);
      if (facts.isEmpty) {
        throw const DataException('The fact catalogue is empty');
      }
      return _cache = facts;
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw DataException('Could not read the fact catalogue', cause: error);
    }
  }
}
