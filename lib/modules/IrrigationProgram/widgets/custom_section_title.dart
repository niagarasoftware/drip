import 'package:flutter/material.dart';

Widget buildSectionTitle({required String title, required BuildContext context}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    height: 25,
    width: 100,
    decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(3))
    ),
    child: Center(
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white,),
      ),
    ),
  );
}