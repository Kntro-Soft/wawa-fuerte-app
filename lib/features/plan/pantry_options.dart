/// The preloaded ingredient checklist, by region.
///
/// OWNER: P3 (UI), to be replaced by P2's corpus-derived list.
///
/// Flow B step 1 says "multi-select checklist (preloaded by region) + free-text
/// other". Preloading matters more than it looks: every ingredient offered as a
/// chip is one the caregiver does not have to spell on a phone keyboard. The
/// free-text field stays because no list of twelve covers a real kitchen.
///
/// Ordered roughly by how commonly they appear in the INS anti-anemia recipes,
/// so the iron-dense items are near the top where they get tapped.
library;

import '../../core/domain/child_profile.dart';

abstract final class PantryOptions {
  /// Available everywhere.
  static const List<String> _common = <String>[
    'sangrecita',
    'higado de pollo',
    'huevo',
    'lentejas',
    'frijol',
    'arroz',
    'papa',
    'cebolla',
    'zanahoria',
    'avena',
  ];

  static const Map<Region, List<String>> _byRegion = <Region, List<String>>{
    Region.coast: <String>['camote', 'zapallo', 'pollo', 'acelga'],
    Region.highlands: <String>['quinua', 'tarwi', 'trigo', 'habas'],
    Region.jungle: <String>['platano', 'yuca', 'pescado', 'frejol'],
  };

  /// The chips shown for a family in [region].
  static List<String> forRegion(Region region) => <String>[
    ..._common,
    ...?_byRegion[region],
  ];

  /// Display form: the corpus stores ingredient names lowercase and unaccented,
  /// which is right for matching and wrong for reading. Chips are capitalised
  /// here at the last moment, so the value sent to the retriever stays the
  /// corpus form.
  static String label(String ingredient) => ingredient.isEmpty
      ? ingredient
      : ingredient[0].toUpperCase() + ingredient.substring(1);
}
