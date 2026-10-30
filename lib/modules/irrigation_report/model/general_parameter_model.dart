class GeneralParameterModel {
  final String payloadKey;
  final String uiKey;
  bool show;
  bool isRequired;

  GeneralParameterModel({
    required this.payloadKey,
    required this.uiKey,
    required this.show,
    this.isRequired = false,
  });
}
