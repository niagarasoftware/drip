import 'package:flutter/material.dart';

class NoCustomers extends StatelessWidget {
  const NoCustomers({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Customers not found.', style: TextStyle(fontSize: 17)),
            SizedBox(height: 5),
            Text(
              'Add your customer using top of the customer adding button.',
              textAlign: TextAlign.center,
            ),
            Icon(Icons.person_add_outlined),
          ],
        ),
      ),
    );
  }
}