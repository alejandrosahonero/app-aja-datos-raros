@Tags(<String>['golden'])
library;

import 'dart:io';

import 'package:aja/app.dart';
import 'package:aja/features/facts/domain/fact.dart';
import 'package:aja/features/facts/presentation/providers/facts_providers.dart';
import 'package:aja/services/billing/premium_controller.dart';
import 'package:aja/services/billing/premium_state.dart';
import 'package:aja/services/storage/storage_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screenshots of the branded screens with the real fonts, light and dark.
///
/// They are for looking at after every visual change: they catch overlaps and
/// clipped text that assertions do not. Pixels differ between operating
/// systems, so the masters are only meaningful on the machine that made them.
/// Regenerate with:
///
///     flutter test --update-goldens --tags golden
///
/// Run on Windows only (where the masters were made); skipped elsewhere.

class _FakePremiumController extends PremiumController {
  @override
  Future<PremiumStatus> build() async =>
      const PremiumStatus(isPremium: true, storeAvailable: false);
}

const Fact _banana = Fact(
  id: 'platano-baya',
  category: FactCategory.science,
  question: LocalizedText(
    es: '¿Cuál de estas dos es una baya: el plátano o la fresa?',
    en: 'Which of these is a berry: the banana or the strawberry?',
  ),
  answer: LocalizedText(
    es: 'El plátano. La fresa, botánicamente, ni siquiera es una fruta única.',
    en: "The banana. The strawberry, botanically, isn't even a single fruit.",
  ),
  detail: LocalizedText(
    es:
        'Una baya nace de un solo ovario y lleva las semillas dentro: '
        'plátano, tomate, uva, aguacate.',
    en:
        'A berry grows from a single ovary with the seeds inside: banana, '
        'tomato, grape, avocado.',
  ),
  source: 'Britannica — Berry (plant reproductive body)',
  sourceUrl: 'https://www.britannica.com/science/berry-plant-reproductive-body',
);

Future<void> _loadFonts() async {
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());

  await (FontLoader(
    'YoungSerif',
  )..addFont(read('assets/fonts/YoungSerif-Regular.ttf'))).load();
  final FontLoader figtree = FontLoader('Figtree');
  for (final String w in <String>['Regular', 'Medium', 'SemiBold', 'Bold']) {
    figtree.addFont(read('assets/fonts/Figtree-$w.ttf'));
  }
  await figtree.load();
}

Future<void> _pump(
  WidgetTester tester, {
  required String theme,
  bool welcome = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2280);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = const <Locale>[Locale('es')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  SharedPreferences.setMockInitialValues(<String, Object>{
    'welcome_seen': !welcome,
    'theme_mode': theme,
  });
  final SharedPreferences preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        premiumControllerProvider.overrideWith(_FakePremiumController.new),
        factsProvider.overrideWith(
          (Ref ref) async => <Fact>[
            _banana,
            _banana.copyWithId('platano-baya-2'),
            _banana.copyWithId('platano-baya-3'),
          ],
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Tests draw shadows as solid outlines by default, which hides what these
/// screenshots are for. The flag must be restored before the test ends.
Future<void> _shot(WidgetTester tester, String file) async {
  debugDisableShadows = false;
  try {
    await tester.pump();
    await expectLater(find.byType(App), matchesGoldenFile(file));
  } finally {
    debugDisableShadows = true;
  }
}

void main() {
  setUpAll(_loadFonts);

  // The shake-to-undo detector talks to the accelerometer plugin, which has
  // no implementation under test.
  setUp(() {
    final TestDefaultBinaryMessenger messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final String channel in <String>[
      'dev.fluttercommunity.plus/sensors/method',
      'dev.fluttercommunity.plus/sensors/user_accel',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (MethodCall call) async => null,
      );
    }
  });

  final bool skip = !Platform.isWindows;

  for (final String theme in <String>['light', 'dark']) {
    testWidgets('deck front, $theme', skip: skip, (WidgetTester tester) async {
      await _pump(tester, theme: theme);
      await _shot(tester, 'masters/deck_front_$theme.png');
    });

    testWidgets('deck answer, $theme', skip: skip, (WidgetTester tester) async {
      await _pump(tester, theme: theme);
      await tester.tap(find.byTooltip('Ver respuesta'));
      await tester.pumpAndSettle();
      await _shot(tester, 'masters/deck_answer_$theme.png');
    });
  }

  testWidgets('welcome', skip: skip, (WidgetTester tester) async {
    await _pump(tester, theme: 'light', welcome: true);
    await _shot(tester, 'masters/welcome.png');
  });
}

extension on Fact {
  Fact copyWithId(String id) => Fact(
    id: id,
    category: category,
    question: question,
    answer: answer,
    detail: detail,
    source: source,
    sourceUrl: sourceUrl,
  );
}
