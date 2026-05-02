import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatNumber(dynamic number) {
  var f = NumberFormat("#.##0.00", "en_US");
  if (number == null) {
    return "";
  }

  return f.format(number);
}

void alertBox(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("OK"),
        ),
      ],
    ),
  );
}
