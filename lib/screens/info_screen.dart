import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/common_widgets.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        InfoCard(
          title: AppStrings.infoCompanyAsTitle,
          body: AppStrings.infoCompanyAs,
        ),
        InfoCard(
          title: AppStrings.infoCompanyBoschTitle,
          body: AppStrings.infoCompanyBosch,
        ),
        InfoCard(
          title: AppStrings.infoWageTitle,
          body: AppStrings.infoWageDetail,
          highlighted: true,
        ),
        InfoCard(
          title: AppStrings.infoBenefitTitle,
          body: AppStrings.infoBenefitDetail,
        ),
      ],
    );
  }
}
