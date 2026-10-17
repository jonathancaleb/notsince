import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const display = TextStyle(
    fontFamily: 'Baloo2',
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );
  static const title = TextStyle(
    fontFamily: 'Baloo2',
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 16,
    height: 1.5,
  );
  static const caption = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 13,
    height: 1.4,
  );
}
