// Fixture: Material now ships as the `material_ui` package (and Cupertino as
// `cupertino_ui`), not only as `package:flutter/material.dart`. Any UI-library
// dependency inside domain/ is the same BLOCKER whichever package it comes from.
// Must keep failing — if it passes, domain purity has a hole the size of the
// whole Material library.

import 'package:material_ui/material_ui.dart';

class Price {
  const Price(this.cents, this.colour);

  final int cents;
  final Color colour;
}
