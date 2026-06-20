import 'package:flutter/cupertino.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/app_theme.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Center(
          child:           Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).appSlogan,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: CupertinoDynamicColor.resolve(
                    AppColors.mutedForeground,
                    context,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const CupertinoActivityIndicator(radius: 14),
            ],
          ),
        ),
      ),
    );
  }
}
