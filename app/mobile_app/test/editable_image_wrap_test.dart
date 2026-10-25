import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/components/editable_image_wrap.dart';

void main() {
  testWidgets('renders the image grid when reordering is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: EditableImageWrap(
          reorderable: true,
          entries: [
            EditableImageEntry(
              id: ValueKey('img-1'),
              displayUrl: '/tmp/image.png',
            ),
          ],
          // What CreatePostScreen passes while publishing.
          onReorder: null,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets(
    'does not wrap tiles in drag targets when reordering is disabled',
    (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: EditableImageWrap(
            reorderable: true,
            entries: [
              EditableImageEntry(
                id: ValueKey('img-1'),
                displayUrl: '/tmp/1.png',
              ),
              EditableImageEntry(
                id: ValueKey('img-2'),
                displayUrl: '/tmp/2.png',
              ),
            ],
            onReorder: null,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(LongPressDraggable<int>), findsNothing);
    },
  );
}
