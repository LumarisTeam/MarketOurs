import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:mobile_app/components/post_editor_form.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'composer keeps publish visible on a small screen with keyboard',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final title = TextEditingController();
      final content = TextEditingController();
      addTearDown(title.dispose);
      addTearDown(content.dispose);
      final formKey = GlobalKey<FormState>();
      var submitted = false;

      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            GlobalCupertinoLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => McThemeData.wrap(child: child!),
          home: CupertinoPageScaffold(
            child: SafeArea(
              child: Form(
                key: formKey,
                child: PostEditorForm(
                  layout: PostEditorLayout.page,
                  titleController: title,
                  contentController: content,
                  selectedTag: null,
                  existingImages: const [],
                  localImages: const [],
                  tagEmptyText: '无标签',
                  submitLabel: '发布',
                  titleValidator: (value) =>
                      value?.trim().isEmpty == true ? '请输入标题' : null,
                  onSubmit: () {
                    submitted = formKey.currentState!.validate();
                  },
                  onPickImages: () {},
                  onPickTag: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('发布'));
      await tester.pumpAndSettle();
      expect(submitted, isFalse);
      expect(find.text('请输入标题'), findsOneWidget);
      await tester.enterText(
        find.byType(CupertinoTextFormFieldRow).first,
        '校园生活',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getBottomLeft(find.text('发布')).dy, lessThan(308));
      await tester.tap(find.text('发布'));
      await tester.pump();
      expect(submitted, isTrue);
    },
  );
}
