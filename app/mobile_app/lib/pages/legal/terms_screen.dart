import 'package:cupertino_ui/cupertino_ui.dart';

import '../../l10n/app_localizations.dart';
import 'legal_web_view_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  /// Hosted on the marketing site so the copy can be updated without a release.
  static final Uri url = Uri.parse('https://lumalis.luckyfishes.site/terms');

  @override
  Widget build(BuildContext context) {
    return LegalWebViewScreen(
      title: AppLocalizations.of(context).profileTerms,
      url: url,
    );
  }
}
