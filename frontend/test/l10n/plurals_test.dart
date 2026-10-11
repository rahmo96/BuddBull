import 'package:buddbull/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('friend-count text reads correctly in English and Hebrew', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final he = lookupAppLocalizations(const Locale('he'));

    expect(en.profileMutualConnections(1), '1 mutual connection');
    expect(en.profileMutualConnections(3), '3 mutual connections');

    expect(he.profileMutualConnections(0), isNot(contains('0 ')));
    expect(he.profileMutualConnections(1), 'חבר משותף אחד');
    expect(he.profileMutualConnections(2), 'שני חברים משותפים');
    expect(he.profileMutualConnections(7), '7 חברים משותפים');
  });
}
