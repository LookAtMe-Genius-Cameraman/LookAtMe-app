import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:wifi/wifi.dart';
import 'package:http/http.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:look_at_me/localization/localizations.dart';

import 'back_button.dart';

String deviceIpAddress;
String devicePort;

foundAndConnectDevice(context, deviceID) async {
  final String ip = await Wifi.ip;
  print(ip);
  final String subnet = ip.substring(0, ip.lastIndexOf('.'));
  final int port = 5000;

  final stream = NetworkAnalyzer.discover2(subnet, port);
  bool isConnected = false;
  int existAddrCount = 0;
  stream.listen((NetworkAddress addr) {
    if (addr.exists) {
      existAddrCount++;
      isConnected =
          _makePostRequest(context, addr.ip, port, '/api/access', deviceID);
    }
  }).onDone(() {
    if (existAddrCount == 0) {
      deviceNotExistAlert(context);
    }
    print('finish.');
  });
}

_makePostRequest(context, ipAddress, port, urls, deviceID) async {
  // set up POST request arguments

  String url = 'http://' + ipAddress + ':' + port.toString() + urls;
  Map<String, String> headers = {
    "Content-type": "application/json; charset=UTF-8"
  };
  String jsonData = '{"id": "' + deviceID + '"}'; // make POST request
  Response response = await post(url,
      headers: headers, body: jsonData); // check the status code for the result
  int statusCode = response
      .statusCode; // this API passes back the id of the new item added to the body
  String responseData = response.body;
  var result = json.decode(responseData);
//    print(result);

  if (result["status"] == "OK") {
    deviceIpAddress = ipAddress;
    devicePort = port.toString();

    Navigator.of(context)
        .push(MaterialPageRoute<Null>(builder: (BuildContext context) {
      SystemChrome.setEnabledSystemUIOverlays([]);
      setConnectedStatus(true);

    return new WebviewScaffold(
      url: 'http://$ipAddress:${port.toString()}$urls?id=${result["data"].toString()}',
      hidden: true,
      appBar: null,
      javascriptChannels: <JavascriptChannel>[
        JavascriptChannel(
          name: 'leaveDevice',
          onMessageReceived: (JavascriptMessage msg) {
            print("leave message received: ${msg.message}");
            print("leave message received!");
            Navigator.pop(context);
            setConnectedStatus(false);
          },
        ),
        JavascriptChannel(
          name: 'shutdownDevice',
          onMessageReceived: (JavascriptMessage msg) {
            print("shutdown message received!");
            Navigator.pop(context);
            setConnectedStatus(false);
            const duration = const Duration(seconds: 1);
            Timer(duration, closeApp);
          },
        ),
      ].toSet(),
    );
    }));
    return true;
  } else if (result["status"] == "ERROR") {
    if (result["message"] == "BUSY") {
      alreadyInUseAlert(context);
      return false;
    }
  }
  deviceNotExistAlert(context);
  return false;
}

alreadyInUseAlert(context) {
  var alertStyle = AlertStyle(
    animationType: AnimationType.fromBottom,
    isCloseButton: false,
    isOverlayTapDismiss: false,
    animationDuration: Duration(milliseconds: 300),
    backgroundColor: Colors.black,
    alertBorder: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color: Colors.grey,
      ),
    ),
    titleStyle: TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: 26,
    ),
    descStyle: TextStyle(
      color: Colors.white,
      fontSize: 14,
    ),
  );

  Alert(
    context: context,
    style: alertStyle,
    type: AlertType.warning,
    title: AppLocalizations.of(context).text('UNAVAILABLE!'),
    desc:
        AppLocalizations.of(context).text('LookAtMe Device is already in use.'),
    buttons: [
      DialogButton(
        child: Text(
          AppLocalizations.of(context).text('OK'),
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        onPressed: () => Navigator.pop(context),
        width: 100,
        color: Colors.deepOrangeAccent,
      )
    ],
  ).show();
}

deviceNotExistAlert(context) {
  var alertStyle = AlertStyle(
    animationType: AnimationType.fromBottom,
    isCloseButton: false,
    isOverlayTapDismiss: false,
    animationDuration: Duration(milliseconds: 300),
    backgroundColor: Colors.black,
    alertBorder: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color: Colors.grey,
      ),
    ),
    titleStyle: TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: 26,
    ),
    descStyle: TextStyle(
      color: Colors.white,
      fontSize: 14,
    ),
  );

  Alert(
    context: context,
    style: alertStyle,
    type: AlertType.warning,
    title: AppLocalizations.of(context).text('Not Exist!'),
    desc: AppLocalizations.of(context).text('LookAtMe is not found.'),
    buttons: [
      DialogButton(
        child: Text(
          AppLocalizations.of(context).text('OK'),
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        onPressed: () => Navigator.pop(context),
        width: 100,
        color: Colors.deepOrangeAccent,
      )
    ],
  ).show();
}

void closeApp() {
  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  exit(0);
}
