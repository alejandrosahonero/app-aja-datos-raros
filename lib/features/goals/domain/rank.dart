/// The ladder the points climb.
///
/// Thresholds are in points, and a met goal pays exactly what the day asked
/// for, so a day is worth 8–15. That puts the second rank inside the first
/// week — early enough to show the user the system works — and the last one out
/// past a hundred completed days, which is where a top rank belongs.
///
/// Each of the first five ranks is split into three tiers — I, II, III —
/// before the name changes, so the ladder reads as sixteen steps instead of
/// six without moving where any of the six names sit or how far the climb
/// runs. The **last** rank, Oráculo, is deliberately left whole: it is the top
/// of the ladder, there is nothing above it to divide the wait into, and
/// splitting it would just be inventing a ceiling nobody asked for. Points
/// earned past it keep counting forever with no further tier to announce —
/// see [next] and [progressTo].
///
/// Flutter-free on purpose, like `FactCategory`: the name and the icon are a
/// presentation concern and live in `rank_style.dart`.
enum Rank {
  curiousI(0),
  curiousII(20),
  curiousIII(40),
  inquisitiveI(60),
  inquisitiveII(100),
  inquisitiveIII(140),
  knowItAllI(180),
  knowItAllII(250),
  knowItAllIII(320),
  scholarI(400),
  scholarII(530),
  scholarIII(660),
  encyclopediaI(800),
  encyclopediaII(1000),
  encyclopediaIII(1200),
  oracle(1400);

  const Rank(this.minPoints);

  /// Points needed to hold this rank.
  final int minPoints;

  /// The highest rank [points] has paid for.
  static Rank forPoints(int points) {
    Rank held = Rank.values.first;
    for (final Rank rank in Rank.values) {
      if (points >= rank.minPoints) held = rank;
    }
    return held;
  }

  /// Which of the six named ranks this tier belongs to (0 = Curioso, …,
  /// 5 = Oráculo). The first five names hold exactly three tiers each, so
  /// integer division by 3 lands all of `curiousI`/`II`/`III` on family 0 and
  /// so on; Oráculo (index 15) lands alone on family 5, since it was never
  /// split. Used to group the ladder by name in the progress screen without
  /// hard-coding which indices belong together there.
  int get family => index ~/ 3;

  /// The next one up, or null at the top of the ladder.
  Rank? get next =>
      index + 1 < Rank.values.length ? Rank.values[index + 1] : null;

  /// Points still owed for [next], or null once there is nothing left to climb.
  int? pointsTo(int points) {
    final Rank? target = next;
    return target == null
        ? null
        : (target.minPoints - points).clamp(0, target.minPoints);
  }

  /// 0→1 across the current band, for the bar on the progress screen.
  ///
  /// Measured from this rank's floor rather than from zero: a bar that fills
  /// once for the whole game would sit at 4% for a month.
  double progressTo(int points) {
    final Rank? target = next;
    if (target == null) return 1;

    final int band = target.minPoints - minPoints;
    if (band <= 0) return 1;

    return ((points - minPoints) / band).clamp(0.0, 1.0);
  }
}
