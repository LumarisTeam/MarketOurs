import os, re

BASE = r'E:\Programming\MarketOurs\app\mobile_app\lib'
IMPORT_LINE = "import 'package:mobile_app/l10n/app_localizations.dart';\n"

for root, dirs, files in os.walk(BASE):
    dirs[:] = [d for d in dirs if d not in ('l10n', 'models', '.dart_tool')]
    for fname in files:
        if not fname.endswith('.dart'):
            continue
        fpath = os.path.join(root, fname)
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        # 1. Remove bad import if it's the first line (wrong placement)
        if content.startswith(IMPORT_LINE):
            content = content[len(IMPORT_LINE):]

        # 2. Add import in correct place (after package:flutter imports)
        lines = content.split('\n')
        new_lines = []
        import_added = False
        for i, line in enumerate(lines):
            new_lines.append(line)
            # Add import after the last package:flutter line
            if not import_added and 'package:flutter' in line and 'import' in line:
                # Check if next line is also a flutter import
                next_is_flutter = (i+1 < len(lines) and 'package:flutter' in lines[i+1] and 'import' in lines[i+1])
                if not next_is_flutter:
                    if IMPORT_LINE.strip() not in content:
                        new_lines.append(IMPORT_LINE.rstrip('\n'))
                        import_added = True
        content = '\n'.join(new_lines)

        # 3. Fix `const Text(AppLocalizations...)` or `const Widget(AppLocalizations...)`
        # Remove const when followed by AppLocalizations usage
        content = re.sub(
            r"const (\w+)\(\s*AppLocalizations",
            r"\1(AppLocalizations",
            content
        )

        # 4. Fix default parameter values using context (not allowed in Dart)
        # Pattern: this.emptyText = AppLocalizations.of(context)!.xxx
        # Change to: a non-const default that's resolved in build
        content = re.sub(
            r"= AppLocalizations\.of\(context\)!\.(\w+);",
            r"''; // localized default, caller must supply",
            content
        )

        if content != original:
            with open(fpath, 'w', encoding='utf-8') as f:
                f.write(content)
            relpath = os.path.relpath(fpath, BASE)
            print(f'  Fixed: {relpath}')

print('Done fixing')
