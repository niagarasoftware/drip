class ServiceRequest {
  final int ticketId;
  final String name;
  final String mobileNumber;
  final String issueDescription;
  final List<IssueType> issueType;
  final List<IssueStatus> issueStatus;
  final List<TicketHandler> ticketHandler;
  final List<String> images;

  ServiceRequest({
    required this.ticketId,
    required this.name,
    required this.mobileNumber,
    required this.issueDescription,
    required this.issueType,
    required this.issueStatus,
    required this.ticketHandler,
    this.images = const [],
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      ticketId: json['tickedId'] ?? 0,
      name: json['name'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      issueDescription: json['issueDescription'] ?? '',
      issueType: (json['issueType'] as List? ?? [])
          .map((e) => IssueType.fromJson(e))
          .toList(),
      issueStatus: (json['issueStatus'] as List? ?? [])
          .map((e) => IssueStatus.fromJson(e))
          .toList(),
      ticketHandler: (json['ticketHandler'] as List? ?? [])
          .map((e) => TicketHandler.fromJson(e))
          .toList(),
      images: List<String>.from(json['images'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'tickedId': ticketId,
    'name': name,
    'mobileNumber': mobileNumber,
    'issueDescription': issueDescription,
    'issueType': issueType.map((e) => e.toJson()).toList(),
    'issueStatus': issueStatus.map((e) => e.toJson()).toList(),
    'ticketHandler': ticketHandler.map((e) => e.toJson()).toList(),
    'images': images,
  };
}

class IssueType {
  final int sNo;
  final String type;
  final bool value;

  IssueType({required this.sNo, required this.type, required this.value});

  factory IssueType.fromJson(Map<String, dynamic> json) {
    return IssueType(
      sNo: json['sNo'] ?? 0,
      type: json['type'] ?? '',
      value: json['value'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'sNo': sNo,
    'type': type,
    'value': value,
  };
}

class IssueStatus {
  final int sNo;
  final String name;
  final bool value;
  final bool display;

  IssueStatus({
    required this.sNo,
    required this.name,
    required this.value,
    required this.display,
  });

  factory IssueStatus.fromJson(Map<String, dynamic> json) {
    return IssueStatus(
      sNo: json['sNo'] ?? 0,
      name: json['name'] ?? '',
      value: json['value'] ?? false,
      display: json['display'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'sNo': sNo,
    'name': name,
    'value': value,
    'display': display,
  };
}

class TicketHandler {
  final int sNo;
  final String name;
  final String mobileNumber;
  final String statusMessage;
  final List<TargetDate> targetDates;
  final List<SalesPerson> salesPerson;

  TicketHandler({
    required this.sNo,
    required this.name,
    required this.mobileNumber,
    required this.statusMessage,
    required this.targetDates,
    required this.salesPerson,
  });

  factory TicketHandler.fromJson(Map<String, dynamic> json) {
    return TicketHandler(
      sNo: json['sNo'] ?? 0,
      name: json['name'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      statusMessage: json['statusMessage'] ?? '',
      targetDates: (json['targetDates'] as List? ?? [])
          .map((e) => TargetDate.fromJson(e))
          .toList(),
      salesPerson: (json['salesPerson'] as List? ?? [])
          .map((e) => SalesPerson.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'sNo': sNo,
    'name': name,
    'mobileNumber': mobileNumber,
    'statusMessage': statusMessage,
    'targetDates': targetDates.map((e) => e.toJson()).toList(),
    'salesPerson': salesPerson.map((e) => e.toJson()).toList(),
  };
}

class TargetDate {
  final String date;
  final String reason;

  TargetDate({required this.date, required this.reason});

  factory TargetDate.fromJson(Map<String, dynamic> json) {
    return TargetDate(
      date: json['date'] ?? '',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'reason': reason,
  };
}

class SalesPerson {
  final int sNo;
  final String name;
  final String mobileNumber;
  final String statusMessage;

  SalesPerson({
    required this.sNo,
    required this.name,
    required this.mobileNumber,
    required this.statusMessage,
  });

  factory SalesPerson.fromJson(Map<String, dynamic> json) {
    return SalesPerson(
      sNo: json['sNo'] ?? 0,
      name: json['name'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      statusMessage: json['statusMessage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'sNo': sNo,
    'name': name,
    'mobileNumber': mobileNumber,
    'statusMessage': statusMessage,
  };
}
