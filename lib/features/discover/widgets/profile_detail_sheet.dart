import 'package:flutter/material.dart';

import '../../../core/models/user_models.dart';
import '../../match/widgets/match_profile_detail_sheet.dart';

/// Discover uses the same web-style profile sheet as Match (DuoFrontend
/// `ProfileDetailSheet`), which also records the profile visit.
void showProfileDetailSheet(
  BuildContext context, {
  required DuoProfile profile,
  String? timeLabel,
}) {
  showMatchProfileDetail(context, profile: profile, subtitle: timeLabel);
}
