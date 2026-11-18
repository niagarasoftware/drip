import '../model/service_request_model.dart';

class ServiceRequestRepository {
  Future<List<ServiceRequest>> getTickets() async {
    // Mocking data using the provided structure
    final List<Map<String, dynamic>> rawData = [
      {
        'tickedId': 104,
        'name': 'S.SIVA',
        'mobileNumber': '9876543210',
        'issueDescription': 'Valve Not Opening Zone 3 Irrigation valve does not open during the scheduled irrigation cycle.',
        'issueType': [
          {'sNo': 1, 'type': 'Application', 'value': false},
          {'sNo': 2, 'type': 'Hardware', 'value': true},
          {'sNo': 3, 'type': 'Valve', 'value': false},
          {'sNo': 4, 'type': 'Filter', 'value': false},
          {'sNo': 5, 'type': 'Fertilizer', 'value': false},
          {'sNo': 6, 'type': 'Sensors', 'value': false},
          {'sNo': 7, 'type': 'Others', 'value': false},
        ],
        'issueStatus': [
          {'sNo': 1, 'name': 'Customer Raised Complaint', 'value': true, 'display': true},
          {'sNo': 2, 'name': 'Ticket Responsible Person', 'value': true, 'display': true},
          {'sNo': 3, 'name': 'Escalated to the company', 'value': false, 'display': true},
          {'sNo': 4, 'name': 'Ticket Closed', 'value': false, 'display': true},
        ],
        'ticketHandler': [
          {
            'sNo': 1,
            'name': 'Saravanan',
            'mobileNumber': '9876543210',
            'statusMessage': 'Electrical Engineer',
            'targetDates': [
              {'date': 'Jul 22, 9:14 AM', 'reason': 'The X200 Controller is Powered Off.'},
            ],
            'salesPerson': [
              {'sNo': 1, 'name': 'Venkatesan', 'mobileNumber': '9876543211', 'statusMessage': 'Dealer'},
              {'sNo': 2, 'name': 'RAHUL', 'mobileNumber': '9876543212', 'statusMessage': 'Technician'},
            ]
          }
        ],
        'images': [
          'https://picsum.photos/400/300?random=1',
          'https://picsum.photos/400/300?random=2',
        ]
      },
      {
        'tickedId': 101,
        'name': 'S.SURIYA',
        'mobileNumber': '9876543211',
        'issueDescription': 'Valve Not Opening Zone 3 Irrigation valve does not open during the scheduled irrigation cycle.',
        'issueType': [
          {'sNo': 2, 'type': 'Hardware', 'value': true},
        ],
        'issueStatus': [
          {'sNo': 1, 'name': 'Customer Raised Complaint', 'value': true, 'display': true},
          {'sNo': 2, 'name': 'Ticket Responsible Person', 'value': false, 'display': true},
        ],
        'ticketHandler': [],
        'images': [
          'https://picsum.photos/400/300?random=3',
        ]
      }
    ];

    return rawData.map((json) => ServiceRequest.fromJson(json)).toList();
  }
}
