enum Flavor {
  oroDevelopment,
  oroProduction,
  smartComm,
  agritel
}

class F {
  static Flavor? appFlavor;

  static String get name => appFlavor?.name ?? '';

  static String get title {
    switch (appFlavor) {
      case Flavor.oroDevelopment:
        return 'ORO';
      case Flavor.oroProduction:
        return 'ORO';
      case Flavor.smartComm:
        return 'SMART COMM';
      case Flavor.agritel:
        return 'Agritel';
      default:
        return 'title';
    }
  }
}