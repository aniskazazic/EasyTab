import 'dart:convert';

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

Image imageFromBase64String(String base64String) {
  return Image.memory(base64Decode(base64String), height: 200, width: 200);
}
