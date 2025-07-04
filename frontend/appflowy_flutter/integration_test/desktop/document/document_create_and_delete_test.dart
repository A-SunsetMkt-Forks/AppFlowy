import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('create and delete the document:', () {
    testWidgets('create a new document when launching app in first time',
        (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapAnonymousSignInButton();
      final finder = find.text(gettingStarted, findRichText: true);
      await tester.pumpUntilFound(finder, timeout: const Duration(seconds: 2));

      // create a new document
      const pageName = 'Test Document';
      await tester.createNewPageWithNameUnderParent(name: pageName);

      // expect to see a new document
      tester.expectToSeePageName(pageName);
      // and with one paragraph block
      expect(find.byType(ParagraphBlockComponentWidget), findsOneWidget);
    });

    testWidgets('delete the readme page and restore it', (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapAnonymousSignInButton();

      // delete the readme page
      await tester.hoverOnPageName(
        gettingStarted,
        onHover: () async => tester.tapDeletePageButton(),
      );

      // the banner should show up and the readme page should be gone
      tester.expectToSeeDocumentBanner();
      tester.expectNotToSeePageName(gettingStarted);

      // restore the readme page
      await tester.tapRestoreButton();

      // the banner should be gone and the readme page should be back
      tester.expectNotToSeeDocumentBanner();
      tester.expectToSeePageName(gettingStarted);
    });

    testWidgets('delete the readme page and delete it permanently',
        (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapAnonymousSignInButton();

      // delete the readme page
      await tester.hoverOnPageName(
        gettingStarted,
        onHover: () async => tester.tapDeletePageButton(),
      );

      // the banner should show up and the readme page should be gone
      tester.expectToSeeDocumentBanner();
      tester.expectNotToSeePageName(gettingStarted);

      // delete the page permanently
      await tester.tapDeletePermanentlyButton();

      // the banner should be gone and the readme page should be gone
      tester.expectNotToSeeDocumentBanner();
      tester.expectNotToSeePageName(gettingStarted);
    });
  });
}
