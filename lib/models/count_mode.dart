enum CountMode {
  quick,
  professional;

  static CountMode fromStored(String? value) {
    for (final mode in CountMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return CountMode.professional;
  }
}
