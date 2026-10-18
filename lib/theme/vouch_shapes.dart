/// Corner and outline tokens shared across screens.
library;

import 'package:flutter/material.dart';

class VouchShapes {
  const VouchShapes._();

  static const BorderRadius card = BorderRadius.all(Radius.circular(28));
  static const BorderRadius large = BorderRadius.all(Radius.circular(36));
  static const BorderRadius small = BorderRadius.all(Radius.circular(16));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(34));
  static const BorderRadius bottomBar =
      BorderRadius.vertical(top: Radius.circular(28));

  static const StadiumBorder pill = StadiumBorder();
  static const CircleBorder circle = CircleBorder();
}
