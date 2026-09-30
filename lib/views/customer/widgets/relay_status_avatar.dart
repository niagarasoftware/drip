import 'package:flutter/material.dart';

class RelayStatusAvatar extends StatelessWidget {
  final int? status;
  final int? rlyNo;
  final String? objType;
  final double sNo;

  const RelayStatusAvatar({
    super.key,
    required this.status,
    required this.rlyNo,
    required this.objType,
    required this.sNo,
  });

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.redAccent;
      default:
        return Colors.black12;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: (sNo.toString().startsWith('23.') || sNo.toString().startsWith('40.')) ?
          _getStatusColor(0) : _getStatusColor(status!),
          child: Text(
            getLabel(objType, rlyNo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ),
        if(sNo.toString().startsWith('23.') || sNo.toString().startsWith('40.'))...[
          Positioned(
            bottom : 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: status == 0 ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                status == 0 ? 'Low' : 'High',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],

      ],
    );
  }

  String getLabel(String? objType, int? rlyNo) {
    final no = (rlyNo ?? 0).toString();
    if (objType == "1,2") {
      return 'RL-$no';
    }else if (objType == "3") {
      return 'Ai-$no';
    }else if (objType == "4") {
      if(no=='5' && sNo.toString().startsWith('23.')){
        return 'Di-6';
      }
      return 'Di-$no';
    }else if (objType == "5") {
      return 'Mi-$no';
    }else if (objType == "6") {
      return 'Pi-$no';
    }else if (objType == "7") {
      return 'i2c-$no';
    }
    return 'PmI-$no';
  }
}