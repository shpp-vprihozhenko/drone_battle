import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

int deadCounter=0, liveCounter=0;
String nodeEndPoint = 'http://173.212.250.234:6641';
List <UserResult> url = [];

class UserResult {
  String name = '';
  int score = 0;
}

showAlertPage(context, String msg) async {
  await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
        );
      }
  );
}

Future <String> addBestResult (context, String name, int score) async {
  print('addBestResult $name $score');
  var resp = await http.post(
    Uri.parse('$nodeEndPoint/addBestResult'),
    headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8',},
    body: jsonEncode(
        <String, dynamic>{
          'name': name,
          'score': score,
        }
    ),
  );
  if (resp.body == null || resp.body.substring(0,2) != 'ok') {
    showAlertPage(context, 'Error. Try later\n${resp.body}');
    return '';
  }
  return 'ok';
}

getBestResults (context) async {
  print('getBestResults');
  var resp = await http.post(
    Uri.parse('$nodeEndPoint/getBestResult'),
    headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8',},
    body: jsonEncode(
        <String, dynamic>{
          'name': '1',
        }
    ),
  );
  if (resp.body == null || resp.statusCode != 200) {
    showAlertPage(context, 'Error. Try later\n${resp.body}');
    return null;
  }
  //print('got ${resp.body}');
  return jsonDecode(resp.body);
}
