/// The rank ladder: thresholds, what comes next, and how the bar fills.
library;

import 'package:aja/features/goals/domain/rank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rank.forPoints', () {
    test('starts everybody at the bottom', () {
      expect(Rank.forPoints(0), Rank.curiousI);
      expect(Rank.forPoints(-10), Rank.curiousI);
    });

    test('promotes exactly on the threshold, not one point later', () {
      for (final Rank rank in Rank.values) {
        expect(Rank.forPoints(rank.minPoints), rank);
        if (rank != Rank.curiousI) {
          expect(Rank.forPoints(rank.minPoints - 1), isNot(rank));
        }
      }
    });

    test('holds the top rank however many points pile up after it', () {
      expect(Rank.forPoints(Rank.oracle.minPoints * 10), Rank.oracle);
    });

    test('the ladder only ever climbs', () {
      for (int i = 1; i < Rank.values.length; i++) {
        expect(
          Rank.values[i].minPoints,
          greaterThan(Rank.values[i - 1].minPoints),
        );
      }
    });
  });

  group('Rank.next and pointsTo', () {
    test('the top of the ladder has nothing above it', () {
      expect(Rank.oracle.next, isNull);
      expect(Rank.oracle.pointsTo(Rank.oracle.minPoints), isNull);
    });

    test('counts down the points still owed', () {
      final int nextTier = Rank.curiousI.next!.minPoints;
      expect(Rank.curiousI.pointsTo(0), nextTier);
      expect(Rank.curiousI.pointsTo(nextTier - 5), 5);
    });

    test('never reports a negative debt', () {
      final int nextTier = Rank.curiousI.next!.minPoints;
      expect(Rank.curiousI.pointsTo(nextTier + 100), 0);
    });
  });

  group('Rank.progressTo', () {
    test('measures across the current band, not from zero', () {
      // Half way between a tier's floor and the next one's, the bar must read
      // 50% — a bar measured from zero would creep forward even on days that
      // earned nothing towards the next tier.
      final int floor = Rank.inquisitiveI.minPoints;
      final int ceiling = Rank.inquisitiveI.next!.minPoints;
      expect(
        Rank.inquisitiveI.progressTo((floor + ceiling) ~/ 2),
        closeTo(0.5, 0.01),
      );
    });

    test('is empty on arrival and full on departure', () {
      expect(Rank.inquisitiveI.progressTo(Rank.inquisitiveI.minPoints), 0);
      expect(
        Rank.inquisitiveI.progressTo(Rank.inquisitiveI.next!.minPoints),
        1,
      );
    });

    test('is full at the top of the ladder', () {
      expect(Rank.oracle.progressTo(Rank.oracle.minPoints), 1);
    });
  });
}
