import 'dart:convert';

import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:wifi/wifi.dart';
import 'package:http/http.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:look_at_me/web_view.dart';


foundAndConnectDevice(context, deviceID) async {
  final String ip = await Wifi.ip;
  print(ip);
  final String subnet = ip.substring(0, ip.lastIndexOf('.'));
  final int port = 5000;

  final stream = NetworkAnalyzer.discover2('192.168.45', port);
  bool isConnected = false;
  while (!isConnected) {
    stream.listen((NetworkAddress addr) {
      if (addr.exists) {
        isConnected = _makePostRequest(context, addr.ip, port, '/api/access', deviceID);
      }
    }).onDone(() => print('finish.'));
  }
}

_makePostRequest(context, ipAddress, port, urls, deviceID) async {
  // set up POST request arguments

  String url = 'http://' + ipAddress + ':' + port.toString() + urls;
  Map<String, String> headers = {
    "Content-type": "application/json; charset=UTF-8"
  };
  String jsonData =
      '{"id": "' + deviceID + '"}'; // make POST request
  Response response = await post(url,
      headers: headers,
      body: jsonData); // check the status code for the result
  int statusCode = response
      .statusCode; // this API passes back the id of the new item added to the body
  String responseData = response.body;
  var result = json.decode(responseData);
//    print(result);

  if (result["status"] == "OK") {
    Navigator.of(context)
        .push(MaterialPageRoute<Null>(builder: (BuildContext context) {
      SystemChrome.setEnabledSystemUIOverlays([]);
      return new WebViewWebPage(
          url: 'http://$ipAddress:${port.toString()}$urls?id=${result["data"].toString()}');
    }));
    return true;
  }
  return false;
}