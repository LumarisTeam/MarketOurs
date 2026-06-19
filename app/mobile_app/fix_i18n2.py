import os, re

BASE = r'E:\Programming\MarketOurs\app\mobile_app\lib'
IMPORT = "import 'package:mobile_app/l10n/app_localizations.dart';"

for root, dirs, files in os.walk(BASE):
    dirs[:] = [d for d in dirs if d not in ('l10n', 'models', '.dart_tool')]
    for fname in files:
        if not fname.endswith('.dart'):
            continue
        fpath = os.path.join(root, fname)
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        # Remove the bad import if it was added (it gets added in wrong places)
        content = content.replace(IMPORT + '\n', '')

        # Fix 1: Default parameter values with context → use simple default
        # "this.emptyText = AppLocalizations.of(context)!.xxx" → "this.emptyText = 'Tag'"
        content = re.sub(
            r"this\.(\w+) = AppLocalizations\.of\(context\)!\.\w+",
            r"this.\1 = 'Tag'",
            content
        )

        # Fix 2: const lists/maps containing AppLocalizations → remove const
        # Pattern: const [AppLocalizations... or const {AppLocalizations...
        content = re.sub(
            r"const \[([^\]]*AppLocalizations[^\]]*)\]",
            lambda m: '[' + m.group(1) + ']',
            content
        )
        content = re.sub(
            r"const \{([^}]*AppLocalizations[^}]*)\}",
            lambda m: '{' + m.group(1) + '}',
            content
        )
        content = re.sub(
            r"const <[^>]+>\[([^\]]*AppLocalizations[^\]]*)\]",
            lambda m: '[' + m.group(1) + ']',
            content
        )

        # Fix 3: const Text or const CupertinoButton with AppLocalizations
        content = re.sub(
            r"const (Text|CupertinoButton|CupertinoActionSheetAction)\(AppLocalizations",
            r"\1(AppLocalizations",
            content
        )

        if content != original:
            with open(fpath, 'w', encoding='utf-8') as f:
                f.write(content)
            relpath = os.path.relpath(fpath, BASE)
            print(f'  Fixed: {relpath}')

print('Done')
