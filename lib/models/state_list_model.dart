class StateListModel
{
  StateListModel({
    this.countryId = 0,
    this.stateId = 0,
    this.stateName = '',
    this.isoCode1 = '',
  });

  int countryId, stateId;
  String stateName, isoCode1;

  factory StateListModel.fromJson(Map<String, dynamic> json) => StateListModel(
    countryId: json['countryId'],
    stateId: json['stateId'],
    stateName: json['stateName'],
    isoCode1: json['isoCode1'],
  );

  Map<String, dynamic> toJson() => {
    'countryId': countryId,
    'stateId': stateId,
    'stateName': stateName,
    'isoCode1': isoCode1,
  };
}