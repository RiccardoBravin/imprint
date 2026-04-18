import 'package:flutter/material.dart';

class FormatSettings {
  const FormatSettings({
    required this.titleFontSize,
    required this.primaryColor,
    required this.sectionsPerPage,
    this.showFooter = true,
    this.showFee = true,
    this.itemFontSize = 10.0,
    this.itemColor = 0xFF000000,
    this.descFontSize = 8.5,
    this.descColor = 0xFF555555,
    this.footerFontSize = 7.5,
    this.footerColor = 0xFF444444,
    this.logoSize = 80.0,
    this.backgroundColor = 0xFFFFFFFF,
  });

  final double titleFontSize;

  /// Stored as ARGB integer (e.g. 0xFF661A26). Use [color] getter for Flutter Color.
  final int primaryColor;

  final int sectionsPerPage;
  final bool showFooter;
  final bool showFee;

  final double itemFontSize;
  final int itemColor;

  final double descFontSize;
  final int descColor;

  final double footerFontSize;
  final int footerColor;

  /// Logo height in PDF points. Width scales proportionally.
  final double logoSize;

  final int backgroundColor;

  Color get color => Color(primaryColor);
  Color get itemColorValue => Color(itemColor);
  Color get descColorValue => Color(descColor);
  Color get footerColorValue => Color(footerColor);
  Color get backgroundColorValue => Color(backgroundColor);

  static const FormatSettings a4Defaults = FormatSettings(
    titleFontSize: 40,
    primaryColor: 0xFF700E0E,
    sectionsPerPage: 3,
    showFooter: false,
    showFee: true,
    itemFontSize: 14.0,
    itemColor: 0xFF000000,
    descFontSize: 10.0,
    descColor: 0xFF555555,
    footerFontSize: 12.0,
    footerColor: 0xFF444444,
    logoSize: 90.0,
    backgroundColor: 0xFFFFFFFF,
  );

  static const FormatSettings a5Defaults = FormatSettings(
    titleFontSize: 40,
    primaryColor: 0xFF000000,
    sectionsPerPage: 2,
    showFooter: false,
    showFee: true,
    itemFontSize: 13.0,
    itemColor: 0xFF000000,
    descFontSize: 8.5,
    descColor: 0xFF555555,
    footerFontSize: 9.0,
    footerColor: 0xFF444444,
    logoSize: 65.0,
    backgroundColor: 0xFFFFFFFF,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormatSettings &&
          titleFontSize == other.titleFontSize &&
          primaryColor == other.primaryColor &&
          sectionsPerPage == other.sectionsPerPage &&
          showFooter == other.showFooter &&
          showFee == other.showFee &&
          itemFontSize == other.itemFontSize &&
          itemColor == other.itemColor &&
          descFontSize == other.descFontSize &&
          descColor == other.descColor &&
          footerFontSize == other.footerFontSize &&
          footerColor == other.footerColor &&
          logoSize == other.logoSize &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode => Object.hash(
    titleFontSize,
    primaryColor,
    sectionsPerPage,
    showFooter,
    showFee,
    itemFontSize,
    itemColor,
    descFontSize,
    descColor,
    footerFontSize,
    footerColor,
    logoSize,
    backgroundColor,
  );

  FormatSettings copyWith({
    double? titleFontSize,
    int? primaryColor,
    int? sectionsPerPage,
    bool? showFooter,
    bool? showFee,
    double? itemFontSize,
    int? itemColor,
    double? descFontSize,
    int? descColor,
    double? footerFontSize,
    int? footerColor,
    double? logoSize,
    int? backgroundColor,
  }) => FormatSettings(
    titleFontSize: titleFontSize ?? this.titleFontSize,
    primaryColor: primaryColor ?? this.primaryColor,
    sectionsPerPage: sectionsPerPage ?? this.sectionsPerPage,
    showFooter: showFooter ?? this.showFooter,
    showFee: showFee ?? this.showFee,
    itemFontSize: itemFontSize ?? this.itemFontSize,
    itemColor: itemColor ?? this.itemColor,
    descFontSize: descFontSize ?? this.descFontSize,
    descColor: descColor ?? this.descColor,
    footerFontSize: footerFontSize ?? this.footerFontSize,
    footerColor: footerColor ?? this.footerColor,
    logoSize: logoSize ?? this.logoSize,
    backgroundColor: backgroundColor ?? this.backgroundColor,
  );
}
