class CountryListModel
{
  CountryListModel({
    this.countryId = 0,
    this.countryName = '',
    this.countryCode = '',
    this.isoCode1 = '',
  });

  int countryId;
  String countryName, countryCode, isoCode1;

  factory CountryListModel.fromJson(Map<String, dynamic> json) => CountryListModel(
    countryId: json['countryId'],
    countryName: json['countryName'],
    countryCode: json['countryCode'],
    isoCode1: json['isoCode1'],
  );

  Map<String, dynamic> toJson() => {
    'countryId': countryId,
    'countryName': countryName,
    'countryCode': countryCode,
    'isoCode1': isoCode1,
  };
}